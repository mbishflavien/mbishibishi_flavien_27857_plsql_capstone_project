---  Package: careconnect_pkg
---  Description: CareConnect PL/SQL Package

--  Create the package specification
CREATE OR REPLACE PACKAGE careconnect_pkg IS

  PROCEDURE register_patient(
    p_first_name  IN VARCHAR2,
    p_last_name   IN VARCHAR2,
    p_gender      IN VARCHAR2,
    p_dob         IN DATE,
    p_phone       IN VARCHAR2,
    p_email       IN VARCHAR2,
    p_address     IN VARCHAR2,
    p_patient_id  OUT NUMBER
  );

  PROCEDURE schedule_appointment(
    p_patient_id IN NUMBER,
    p_doctor_id  IN NUMBER,
    p_date       IN DATE,
    p_time       IN VARCHAR2
  );

  PROCEDURE reschedule_appointment(
    p_appointment_id IN NUMBER,
    p_new_date       IN DATE,
    p_new_time       IN VARCHAR2
  );

  PROCEDURE record_treatment(
    p_appointment_id IN NUMBER,
    p_doctor_id      IN NUMBER,
    p_description    IN VARCHAR2,
    p_prescription   IN VARCHAR2
  );

  PROCEDURE mark_bill_paid(
    p_bill_id IN NUMBER
  );

  FUNCTION calculate_total_unpaid(p_patient_id IN NUMBER) RETURN NUMBER;

  PROCEDURE get_doctor_schedule(
    p_doctor_id IN NUMBER,
    p_date      IN DATE,
    p_cursor    OUT SYS_REFCURSOR
  );

  PROCEDURE generate_patient_report(
    p_patient_id IN NUMBER,
    p_cursor     OUT SYS_REFCURSOR
  );

  FUNCTION avg_wait_time(p_from_date IN DATE, p_to_date IN DATE) RETURN NUMBER;
  FUNCTION monthly_patient_load(p_year_month IN VARCHAR2) RETURN NUMBER;
  FUNCTION doctor_performance_score(p_doctor_id IN NUMBER) RETURN NUMBER;

  PROCEDURE log_audit(
    p_table_name IN VARCHAR2,
    p_operation  IN VARCHAR2,
    p_record_id  IN NUMBER,
    p_old_value  IN CLOB := NULL,
    p_new_value  IN CLOB := NULL,
    p_status     IN VARCHAR2 := NULL,
    p_reason     IN VARCHAR2 := NULL
  );

END careconnect_pkg;
/

CREATE OR REPLACE PACKAGE BODY careconnect_pkg IS

  -- AUDIT LOGGING (Autonomous Transaction)
  PROCEDURE log_audit(
    p_table_name IN VARCHAR2,
    p_operation  IN VARCHAR2,
    p_record_id  IN NUMBER,
    p_old_value  IN CLOB DEFAULT NULL,
    p_new_value  IN CLOB DEFAULT NULL,
    p_status     IN VARCHAR2 DEFAULT NULL,
    p_reason     IN VARCHAR2 DEFAULT NULL
  ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO audit_log(
      table_name, operation, record_id, old_value, new_value,
      attempt_by, attempt_date, status, reason, changed_at
    ) VALUES (
      p_table_name, p_operation, p_record_id, p_old_value, p_new_value,
      USER, SYSDATE, p_status, p_reason, SYSDATE
    );
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
  END log_audit;

  -- REGISTER PATIENT
  PROCEDURE register_patient(
    p_first_name  IN VARCHAR2,
    p_last_name   IN VARCHAR2,
    p_gender      IN VARCHAR2,
    p_dob         IN DATE,
    p_phone       IN VARCHAR2,
    p_email       IN VARCHAR2,
    p_address     IN VARCHAR2,
    p_patient_id  OUT NUMBER
  ) IS
  BEGIN
    IF p_first_name IS NULL OR p_last_name IS NULL THEN
      RAISE_APPLICATION_ERROR(-20001, 'First and last name required');
    END IF;

    INSERT INTO patients(first_name, last_name, gender, dob, phone, email, address)
    VALUES(p_first_name, p_last_name, p_gender, p_dob, p_phone, p_email, p_address)
    RETURNING patient_id INTO p_patient_id;

    log_audit('PATIENTS', 'INSERT', p_patient_id, NULL, 
              'Name='||p_first_name||' '||p_last_name, 'ALLOWED', 'Patient registered');
    COMMIT;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      ROLLBACK;
      log_audit('PATIENTS', 'INSERT', NULL, NULL, NULL, 'DENIED', 'Duplicate phone or email');
      RAISE_APPLICATION_ERROR(-20010, 'Duplicate phone or email');
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20011, 'Error registering patient: ' || SQLERRM);
  END register_patient;

  -- SCHEDULE APPOINTMENT
  PROCEDURE schedule_appointment(
    p_patient_id IN NUMBER,
    p_doctor_id  IN NUMBER,
    p_date       IN DATE,
    p_time       IN VARCHAR2
  ) IS
    v_cnt NUMBER;
    v_new_id NUMBER;
  BEGIN
    -- Validate patient
    SELECT COUNT(*) INTO v_cnt FROM patients WHERE patient_id = p_patient_id;
    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(-20012, 'Patient not found');
    END IF;

    -- Validate doctor
    SELECT COUNT(*) INTO v_cnt FROM doctors WHERE doctor_id = p_doctor_id;
    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(-20013, 'Doctor not found');
    END IF;

    -- Check availability
    SELECT COUNT(*) INTO v_cnt
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND TRUNC(appointment_date) = TRUNC(p_date)
      AND appointment_time = p_time
      AND status IN ('Pending', 'Scheduled');

    IF v_cnt > 0 THEN
      log_audit('APPOINTMENTS','INSERT_ATTEMPT', NULL, NULL, NULL, 
                'DENIED', 'Doctor already booked');
      RAISE_APPLICATION_ERROR(-20014, 'Doctor unavailable at that time');
    END IF;

    INSERT INTO appointments(patient_id, doctor_id, appointment_date, appointment_time, status)
    VALUES(p_patient_id, p_doctor_id, p_date, p_time, 'Pending')
    RETURNING appointment_id INTO v_new_id;

    log_audit('APPOINTMENTS','INSERT', v_new_id, NULL, 
              'Scheduled '||TO_CHAR(p_date,'YYYY-MM-DD'), 'ALLOWED', 'Scheduled');
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      IF SQLCODE BETWEEN -20099 AND -20000 THEN 
        RAISE; 
      END IF;
      RAISE_APPLICATION_ERROR(-20015, 'Scheduling error: ' || SQLERRM);
  END schedule_appointment;

  -- RESCHEDULE APPOINTMENT
  PROCEDURE reschedule_appointment(
    p_appointment_id IN NUMBER,
    p_new_date       IN DATE,
    p_new_time       IN VARCHAR2
  ) IS
    v_doc_id NUMBER;
    v_cnt NUMBER;
  BEGIN
    SELECT doctor_id INTO v_doc_id 
    FROM appointments 
    WHERE appointment_id = p_appointment_id;

    SELECT COUNT(*) INTO v_cnt
    FROM appointments
    WHERE doctor_id = v_doc_id
      AND TRUNC(appointment_date) = TRUNC(p_new_date)
      AND appointment_time = p_new_time
      AND status IN ('Pending', 'Scheduled')
      AND appointment_id != p_appointment_id;

    IF v_cnt > 0 THEN
      log_audit('APPOINTMENTS','RESCHEDULE_ATTEMPT', p_appointment_id, NULL, NULL,
                'DENIED', 'Doctor unavailable at new time');
      RAISE_APPLICATION_ERROR(-20014, 'Doctor unavailable at new time');
    END IF;

    UPDATE appointments
    SET appointment_date = p_new_date, appointment_time = p_new_time
    WHERE appointment_id = p_appointment_id;

    log_audit('APPOINTMENTS','UPDATE', p_appointment_id, 'reschedule', 
              'new:'||TO_CHAR(p_new_date,'YYYY-MM-DD'), 'ALLOWED', 'Rescheduled');
    COMMIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20016, 'Appointment not found');
    WHEN OTHERS THEN
      ROLLBACK;
      IF SQLCODE BETWEEN -20099 AND -20000 THEN 
        RAISE; 
      END IF;
      RAISE_APPLICATION_ERROR(-20017, 'Reschedule error: ' || SQLERRM);
  END reschedule_appointment;

  -- RECORD TREATMENT
  PROCEDURE record_treatment(
    p_appointment_id IN NUMBER,
    p_doctor_id      IN NUMBER,
    p_description    IN VARCHAR2,
    p_prescription   IN VARCHAR2
  ) IS
    v_cnt NUMBER;
    v_new_id NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_cnt 
    FROM appointments 
    WHERE appointment_id = p_appointment_id;
    
    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(-20018, 'Appointment not found');
    END IF;

    INSERT INTO treatments(appointment_id, doctor_id, description, prescription, treatment_date)
    VALUES(p_appointment_id, p_doctor_id, p_description, p_prescription, SYSDATE)
    RETURNING treatment_id INTO v_new_id;

    UPDATE appointments 
    SET status = 'Completed' 
    WHERE appointment_id = p_appointment_id;

    log_audit('TREATMENTS','INSERT', v_new_id, NULL, 
              p_description, 'ALLOWED', 'Treatment recorded');
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      IF SQLCODE BETWEEN -20099 AND -20000 THEN 
        RAISE; 
      END IF;
      RAISE_APPLICATION_ERROR(-20019, 'Treatment error: ' || SQLERRM);
  END record_treatment;

  -- MARK BILL PAID
  PROCEDURE mark_bill_paid(
    p_bill_id IN NUMBER
  ) IS
    v_old_status VARCHAR2(20);
  BEGIN
    SELECT status INTO v_old_status
    FROM billing 
    WHERE bill_id = p_bill_id;

    UPDATE billing 
    SET status = 'Paid', payment_date = SYSDATE 
    WHERE bill_id = p_bill_id;

    log_audit('BILLING','UPDATE', p_bill_id, 
              'status='||v_old_status, 'status=Paid', 'ALLOWED', 'Paid');
    COMMIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20020, 'Bill not found');
    WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20021, 'Billing error: ' || SQLERRM);
  END mark_bill_paid;

  -- CALCULATE TOTAL UNPAID
  FUNCTION calculate_total_unpaid(p_patient_id IN NUMBER) RETURN NUMBER IS
    v_sum NUMBER := 0;
  BEGIN
    SELECT NVL(SUM(b.amount),0) INTO v_sum
    FROM billing b
    JOIN treatments t ON b.treatment_id = t.treatment_id
    JOIN appointments a ON t.appointment_id = a.appointment_id
    WHERE a.patient_id = p_patient_id
      AND NVL(b.status,'Unpaid') != 'Paid';
    RETURN v_sum;
  EXCEPTION
    WHEN OTHERS THEN 
      RETURN 0;
  END calculate_total_unpaid;

  -- GET DOCTOR SCHEDULE
  PROCEDURE get_doctor_schedule(
    p_doctor_id IN NUMBER,
    p_date      IN DATE,
    p_cursor    OUT SYS_REFCURSOR
  ) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT 
        a.appointment_id,
        p.first_name || ' ' || p.last_name AS patient_name,
        a.appointment_date,
        a.appointment_time,
        a.status
      FROM appointments a
      JOIN patients p ON a.patient_id = p.patient_id
      WHERE a.doctor_id = p_doctor_id
        AND TRUNC(a.appointment_date) = TRUNC(p_date)
      ORDER BY a.appointment_time;
  EXCEPTION
    WHEN OTHERS THEN
      IF p_cursor%ISOPEN THEN 
        CLOSE p_cursor; 
      END IF;
      RAISE_APPLICATION_ERROR(-20022, 'Schedule error: ' || SQLERRM);
  END get_doctor_schedule;

  -- GENERATE PATIENT REPORT
  PROCEDURE generate_patient_report(
    p_patient_id IN NUMBER,
    p_cursor     OUT SYS_REFCURSOR
  ) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT 
        p.patient_id,
        p.first_name || ' ' || p.last_name AS patient_name,
        COUNT(DISTINCT a.appointment_id) AS total_appointments,
        COUNT(DISTINCT t.treatment_id) AS total_treatments,
        NVL(SUM(b.amount),0) AS total_billed,
        NVL(SUM(CASE WHEN b.status = 'Paid' THEN b.amount ELSE 0 END),0) AS total_paid
      FROM patients p
      LEFT JOIN appointments a ON p.patient_id = a.patient_id
      LEFT JOIN treatments t ON a.appointment_id = t.appointment_id
      LEFT JOIN billing b ON t.treatment_id = b.treatment_id
      WHERE p.patient_id = p_patient_id
      GROUP BY p.patient_id, p.first_name, p.last_name;
  EXCEPTION
    WHEN OTHERS THEN
      IF p_cursor%ISOPEN THEN 
        CLOSE p_cursor; 
      END IF;
      RAISE_APPLICATION_ERROR(-20023, 'Report error: ' || SQLERRM);
  END generate_patient_report;

  -- AVERAGE WAIT TIME
  FUNCTION avg_wait_time(p_from_date IN DATE, p_to_date IN DATE) RETURN NUMBER IS
    v_avg NUMBER := 0;
  BEGIN
    SELECT AVG(
      (t.treatment_date - 
       TO_DATE(TO_CHAR(a.appointment_date,'YYYY-MM-DD') || ' ' || a.appointment_time, 
               'YYYY-MM-DD HH24:MI')
      ) * 24 * 60
    ) INTO v_avg
    FROM treatments t
    JOIN appointments a ON t.appointment_id = a.appointment_id
    WHERE t.treatment_date BETWEEN p_from_date AND p_to_date
      AND a.appointment_time IS NOT NULL;

    RETURN NVL(ROUND(v_avg, 2), 0);
  EXCEPTION
    WHEN OTHERS THEN 
      RETURN 0;
  END avg_wait_time;

  -- MONTHLY PATIENT LOAD
  FUNCTION monthly_patient_load(p_year_month IN VARCHAR2) RETURN NUMBER IS
    v_count NUMBER := 0;
  BEGIN
    SELECT COUNT(DISTINCT a.patient_id) INTO v_count
    FROM appointments a
    WHERE TO_CHAR(a.appointment_date,'YYYY-MM') = p_year_month;
    RETURN NVL(v_count, 0);
  EXCEPTION
    WHEN OTHERS THEN 
      RETURN 0;
  END monthly_patient_load;

  -- DOCTOR PERFORMANCE SCORE
  FUNCTION doctor_performance_score(p_doctor_id IN NUMBER) RETURN NUMBER IS
    v_avg_rating NUMBER := 0;
    v_treat_count NUMBER := 0;
    v_score NUMBER := 0;
  BEGIN
    SELECT NVL(AVG(f.rating), 0), NVL(COUNT(t.treatment_id), 0)
    INTO v_avg_rating, v_treat_count
    FROM doctors d
    LEFT JOIN feedback f ON d.doctor_id = f.doctor_id
    LEFT JOIN treatments t ON d.doctor_id = t.doctor_id
    WHERE d.doctor_id = p_doctor_id;

    -- Score: 50% from rating (0-5 scale), 50% from treatment count (normalized to 100)
    v_score := ((v_avg_rating / 5) * 50) + (LEAST(v_treat_count / 100, 1) * 50);
    RETURN ROUND(v_score, 2);
  EXCEPTION
    WHEN OTHERS THEN 
      RETURN 0;
  END doctor_performance_score;

END careconnect_pkg;
/