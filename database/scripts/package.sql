BEGIN
  EXECUTE IMMEDIATE 'DROP PACKAGE careconnect_pkg';
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE NOT IN (-4021, -4043) THEN RAISE; END IF;
END;
/
-- Package specification
CREATE OR REPLACE PACKAGE careconnect_pkg IS

  -- Procedures & functions (API)
  PROCEDURE register_patient(
    p_first_name  IN patients.first_name%TYPE,
    p_last_name   IN patients.last_name%TYPE,
    p_gender      IN patients.gender%TYPE,
    p_dob         IN patients.dob%TYPE,
    p_phone       IN patients.phone%TYPE,
    p_email       IN patients.email%TYPE,
    p_address     IN patients.address%TYPE,
    p_patient_id  OUT patients.patient_id%TYPE
  );

  PROCEDURE schedule_appointment(
    p_patient_id IN appointments.patient_id%TYPE,
    p_doctor_id  IN appointments.doctor_id%TYPE,
    p_date       IN appointments.appointment_date%TYPE,
    p_time       IN appointments.appointment_time%TYPE
  );

  PROCEDURE reschedule_appointment(
    p_appointment_id IN appointments.appointment_id%TYPE,
    p_new_date       IN appointments.appointment_date%TYPE,
    p_new_time       IN appointments.appointment_time%TYPE
  );

  PROCEDURE record_treatment(
    p_appointment_id IN treatments.appointment_id%TYPE,
    p_doctor_id      IN treatments.doctor_id%TYPE,
    p_description    IN treatments.description%TYPE,
    p_prescription   IN treatments.prescription%TYPE
  );

  PROCEDURE mark_bill_paid(
    p_bill_id IN billing.bill_id%TYPE
  );

  FUNCTION calculate_total_unpaid(p_patient_id IN patients.patient_id%TYPE) RETURN NUMBER;

  PROCEDURE get_doctor_schedule(
    p_doctor_id IN doctors.doctor_id%TYPE,
    p_date      IN DATE,
    p_cursor    OUT SYS_REFCURSOR
  );

  PROCEDURE generate_patient_report(
    p_patient_id IN patients.patient_id%TYPE,
    p_cursor     OUT SYS_REFCURSOR
  );

  -- BI functions
  FUNCTION avg_wait_time(p_from_date IN DATE, p_to_date IN DATE) RETURN NUMBER;
  FUNCTION monthly_patient_load(p_year_month IN VARCHAR2) RETURN NUMBER;
  FUNCTION doctor_performance_score(p_doctor_id IN doctors.doctor_id%TYPE) RETURN NUMBER;

  -- Audit utility (exposed for testing)
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

  -- log_audit: autonomous transaction to ensure audit saved even
  PROCEDURE log_audit(
    p_table_name IN VARCHAR2,
    p_operation  IN VARCHAR2,
    p_record_id  IN NUMBER,
    p_old_value  IN CLOB := NULL,
    p_new_value  IN CLOB := NULL,
    p_status     IN VARCHAR2 := NULL,
    p_reason     IN VARCHAR2 := NULL
  ) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    INSERT INTO audit_log(
      table_name, operation, record_id, old_value, new_value,
      attempt_by, attempt_date, status, reason, changed_at
    )
    VALUES (
      p_table_name,
      p_operation,
      p_record_id,
      p_old_value,
      p_new_value,
      USER,
      SYSDATE,
      p_status,
      p_reason,
      SYSDATE
    );
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      NULL;
  END log_audit;

  -- register_patient: inserts a patient and returns id
  PROCEDURE register_patient(
    p_first_name  IN patients.first_name%TYPE,
    p_last_name   IN patients.last_name%TYPE,
    p_gender      IN patients.gender%TYPE,
    p_dob         IN patients.dob%TYPE,
    p_phone       IN patients.phone%TYPE,
    p_email       IN patients.email%TYPE,
    p_address     IN patients.address%TYPE,
    p_patient_id  OUT patients.patient_id%TYPE
  ) IS
  BEGIN
    INSERT INTO patients(first_name, last_name, gender, dob, phone, email, address)
    VALUES(p_first_name, p_last_name, p_gender, p_dob, p_phone, p_email, p_address)
    RETURNING patient_id INTO p_patient_id;

    log_audit('PATIENTS', 'INSERT', p_patient_id, NULL, 'Name='||p_first_name||' '||p_last_name, 'ALLOWED', 'Patient registered');
    COMMIT;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE_APPLICATION_ERROR(-20010, 'Phone or unique constraint violated when registering patient.');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20011, 'Error registering patient: ' || SUBSTR(SQLERRM,1,200));
  END register_patient;

  -- schedule_appointment: checks doctor availability then insert
  PROCEDURE schedule_appointment(
    p_patient_id IN appointments.patient_id%TYPE,
    p_doctor_id  IN appointments.doctor_id%TYPE,
    p_date       IN appointments.appointment_date%TYPE,
    p_time       IN appointments.appointment_time%TYPE
  ) IS
    v_cnt NUMBER;
    v_new_id appointments.appointment_id%TYPE;
  BEGIN
    -- validate patient exists
    SELECT COUNT(*) INTO v_cnt FROM patients WHERE patient_id = p_patient_id;
    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(-20012, 'Patient not found (ID='||p_patient_id||').');
    END IF;

    -- validate doctor exists
    SELECT COUNT(*) INTO v_cnt FROM doctors WHERE doctor_id = p_doctor_id;
    IF v_cnt = 0 THEN
      RAISE_APPLICATION_ERROR(-20013, 'Doctor not found (ID='||p_doctor_id||').');
    END IF;

    -- check availability (same date & time)
    SELECT COUNT(*) INTO v_cnt
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND TRUNC(appointment_date) = TRUNC(p_date)
      AND appointment_time = p_time
      AND status = 'Pending';

    IF v_cnt > 0 THEN
      log_audit('APPOINTMENTS','INSERT_ATTEMPT', NULL, NULL, NULL, 'DENIED', 'Doctor already booked for that slot');
      RAISE_APPLICATION_ERROR(-20014, 'Doctor unavailable at specified date/time.');
    END IF;

    -- Insert and return id
    INSERT INTO appointments(patient_id, doctor_id, appointment_date, appointment_time, status)
    VALUES(p_patient_id, p_doctor_id, p_date, p_time, 'Pending')
    RETURNING appointment_id INTO v_new_id;

    log_audit('APPOINTMENTS','INSERT', v_new_id, NULL, 'Scheduled '||TO_CHAR(p_date,'YYYY-MM-DD')||' '||p_time, 'ALLOWED', 'Appointment scheduled');
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20015, 'Error scheduling appointment: ' || SUBSTR(SQLERRM,1,200));
  END schedule_appointment;

  -- reschedule_appointment: change date/time with availability check
  PROCEDURE reschedule_appointment(
    p_appointment_id IN appointments.appointment_id%TYPE,
    p_new_date       IN appointments.appointment_date%TYPE,
    p_new_time       IN appointments.appointment_time%TYPE
  ) IS
    v_doc_id NUMBER;
    v_cnt NUMBER;
  BEGIN
    SELECT doctor_id INTO v_doc_id FROM appointments WHERE appointment_id = p_appointment_id;

    SELECT COUNT(*) INTO v_cnt
    FROM appointments
    WHERE doctor_id = v_doc_id
      AND TRUNC(appointment_date) = TRUNC(p_new_date)
      AND appointment_time = p_new_time
      AND status = 'Pending'
      AND appointment_id != p_appointment_id;

    IF v_cnt > 0 THEN
      log_audit('APPOINTMENTS','RESCHEDULE_ATTEMPT', p_appointment_id, NULL, NULL, 'DENIED', 'Doctor unavailable at new slot');
      RAISE_APPLICATION_ERROR(-20014, 'Doctor unavailable at new date/time.');
    END IF;

    UPDATE appointments
    SET appointment_date = p_new_date,
        appointment_time = p_new_time
    WHERE appointment_id = p_appointment_id;

    log_audit('APPOINTMENTS','UPDATE', p_appointment_id, 'reschedule', 'new:'||TO_CHAR(p_new_date,'YYYY-MM-DD')||' '||p_new_time, 'ALLOWED', 'Rescheduled appointment');
    COMMIT;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20016, 'Appointment not found (ID='||p_appointment_id||').');
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20017, 'Error rescheduling appointment: ' || SUBSTR(SQLERRM,1,200));
  END reschedule_appointment;

  -- record_treatment: insert treatment + update appointment status
  PROCEDURE record_treatment(
    p_appointment_id IN treatments.appointment_id%TYPE,
    p_doctor_id      IN treatments.doctor_id%TYPE,
    p_description    IN treatments.description%TYPE,
    p_prescription   IN treatments.prescription%TYPE
  ) IS
    v_app_count NUMBER;
    v_new_treatment_id treatments.treatment_id%TYPE;
  BEGIN
    SELECT COUNT(*) INTO v_app_count FROM appointments WHERE appointment_id = p_appointment_id;
    IF v_app_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20018, 'Appointment not found (ID='||p_appointment_id||').');
    END IF;

    INSERT INTO treatments(appointment_id, doctor_id, description, prescription, treatment_date)
    VALUES(p_appointment_id, p_doctor_id, p_description, p_prescription, SYSDATE)
    RETURNING treatment_id INTO v_new_treatment_id;

    UPDATE appointments SET status = 'Completed' WHERE appointment_id = p_appointment_id;

    log_audit('TREATMENTS','INSERT', v_new_treatment_id, NULL, p_description, 'ALLOWED', 'Treatment recorded');
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20019, 'Error recording treatment: ' || SUBSTR(SQLERRM,1,200));
  END record_treatment;

  -- mark_bill_paid: updates billing status
  PROCEDURE mark_bill_paid(
    p_bill_id IN billing.bill_id%TYPE
  ) IS
    v_count NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_count FROM billing WHERE bill_id = p_bill_id;
    IF v_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20020, 'Bill not found (ID='||p_bill_id||').');
    END IF;

    UPDATE billing SET status = 'Paid', payment_date = SYSDATE WHERE bill_id = p_bill_id;
    log_audit('BILLING','UPDATE', p_bill_id, 'status=Unpaid', 'status=Paid', 'ALLOWED', 'Bill marked paid');
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20021, 'Error marking bill as paid: ' || SUBSTR(SQLERRM,1,200));
  END mark_bill_paid;

  -- calculate_total_unpaid: returns total unpaid amount for patient
  FUNCTION calculate_total_unpaid(p_patient_id IN patients.patient_id%TYPE) RETURN NUMBER IS
    v_sum NUMBER := 0;
  BEGIN
    SELECT NVL(SUM(b.amount),0)
    INTO v_sum
    FROM billing b
    JOIN treatments t ON b.treatment_id = t.treatment_id
    JOIN appointments a ON t.appointment_id = a.appointment_id
    WHERE a.patient_id = p_patient_id
      AND NVL(b.status,'Unpaid') <> 'Paid';

    RETURN v_sum;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END calculate_total_unpaid;

  -- get_doctor_schedule: returns a SYS_REFCURSOR of appointments for date
  PROCEDURE get_doctor_schedule(
    p_doctor_id IN doctors.doctor_id%TYPE,
    p_date      IN DATE,
    p_cursor    OUT SYS_REFCURSOR
  ) IS
  BEGIN
    OPEN p_cursor FOR
    SELECT a.appointment_id,
           p.first_name || ' ' || p.last_name AS patient_name,
           a.appointment_date,
           a.appointment_time,
           a.status
    FROM appointments a
    JOIN patients p ON a.patient_id = p.patient_id
    WHERE a.doctor_id = p_doctor_id
      AND TRUNC(a.appointment_date) = TRUNC(p_date)
    ORDER BY TO_DATE(TO_CHAR(a.appointment_date,'YYYY-MM-DD') || ' ' || a.appointment_time, 'YYYY-MM-DD HH24:MI');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20022, 'Error fetching doctor schedule: ' || SUBSTR(SQLERRM,1,200));
  END get_doctor_schedule;

  -- generate_patient_report: returns summary for patient via ref cursor
  PROCEDURE generate_patient_report(
    p_patient_id IN patients.patient_id%TYPE,
    p_cursor     OUT SYS_REFCURSOR
  ) IS
  BEGIN
    OPEN p_cursor FOR
      SELECT p.patient_id,
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
      RAISE_APPLICATION_ERROR(-20023, 'Error generating patient report: ' || SUBSTR(SQLERRM,1,200));
  END generate_patient_report;

  -- avg_wait_time: average minutes between scheduled appointment datetime and the actual treatment_date (only where treatment recorded)
  FUNCTION avg_wait_time(p_from_date IN DATE, p_to_date IN DATE) RETURN NUMBER IS
    v_avg_minutes NUMBER := 0;
  BEGIN
    SELECT AVG( (t.treatment_date - TO_DATE(TO_CHAR(a.appointment_date,'YYYY-MM-DD') || ' ' || a.appointment_time, 'YYYY-MM-DD HH24:MI')) * 24 * 60 )
    INTO v_avg_minutes
    FROM treatments t
    JOIN appointments a ON t.appointment_id = a.appointment_id
    WHERE t.treatment_date BETWEEN p_from_date AND p_to_date
      AND a.appointment_time IS NOT NULL;

    RETURN NVL(v_avg_minutes, 0);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END avg_wait_time;

  -- monthly_patient_load: distinct patients seen in given month 'YYYY-MM'
  FUNCTION monthly_patient_load(p_year_month IN VARCHAR2) RETURN NUMBER IS
    v_count NUMBER := 0;
  BEGIN
    SELECT COUNT(DISTINCT a.patient_id)
    INTO v_count
    FROM appointments a
    WHERE TO_CHAR(a.appointment_date,'YYYY-MM') = p_year_month;

    RETURN NVL(v_count,0);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END monthly_patient_load;

  -- doctor_performance_score: composite score (0..100)
  FUNCTION doctor_performance_score(p_doctor_id IN doctors.doctor_id%TYPE) RETURN NUMBER IS
    v_avg_rating NUMBER := 0;
    v_treat_count NUMBER := 0;
    v_norm_treat_percentage NUMBER := 0;
    v_score NUMBER := 0;
    v_max_ref NUMBER := 100; 
  BEGIN
    SELECT NVL(AVG(f.rating), 0), NVL(COUNT(t.treatment_id), 0)
    INTO v_avg_rating, v_treat_count
    FROM doctors d
    LEFT JOIN feedback f ON d.doctor_id = f.doctor_id
    LEFT JOIN treatments t ON d.doctor_id = t.doctor_id
    WHERE d.doctor_id = p_doctor_id;

    v_norm_treat_percentage := LEAST(v_treat_count / v_max_ref, 1); -- 0..1

    v_score := ( (v_avg_rating / 5) * 50 ) + ( v_norm_treat_percentage * 50 );

    RETURN ROUND(v_score,2);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 0;
  END doctor_performance_score;

END careconnect_pkg;
/
