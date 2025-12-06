--1. mark_bill_paid
create or replace PROCEDURE mark_bill_paid(
    p_bill_id IN billing.bill_id%TYPE
)
AS
BEGIN
    UPDATE billing
    SET status = 'Paid',
        payment_date = SYSDATE
    WHERE bill_id = p_bill_id;
END;

--2. record_treatment
create or replace PROCEDURE record_treatment(
    p_appointment_id  IN treatments.appointment_id%TYPE,
    p_doctor_id       IN treatments.doctor_id%TYPE,
    p_description     IN treatments.description%TYPE,
    p_prescription    IN treatments.prescription%TYPE
)
AS
BEGIN
    INSERT INTO treatments(appointment_id, doctor_id, description, prescription, treatment_date)
    VALUES(p_appointment_id, p_doctor_id, p_description, p_prescription, SYSDATE);

    UPDATE appointments
    SET status = 'Completed'
    WHERE appointment_id = p_appointment_id;
END;
--3.register_patient
create or replace PROCEDURE register_patient(
    p_first_name   IN patients.first_name%TYPE,
    p_last_name    IN patients.last_name%TYPE,
    p_gender       IN patients.gender%TYPE,
    p_dob          IN patients.dob%TYPE,
    p_phone        IN patients.phone%TYPE,
    p_email        IN patients.email%TYPE,
    p_address      IN patients.address%TYPE,
    p_patient_id   OUT NUMBER
)
AS
BEGIN
    INSERT INTO patients(first_name, last_name, gender, dob, phone, email, address)
    VALUES(p_first_name, p_last_name, p_gender, p_dob, p_phone, p_email, p_address)
    RETURNING patient_id INTO p_patient_id;
END;
--4.schedule_appointment
create or replace PROCEDURE schedule_appointment(
    p_patient_id      IN appointments.patient_id%TYPE,
    p_doctor_id       IN appointments.doctor_id%TYPE,
    p_date            IN appointments.appointment_date%TYPE,
    p_time            IN appointments.appointment_time%TYPE
)
AS
    v_count NUMBER;
BEGIN
    -- Check if doctor already booked
    SELECT COUNT(*) INTO v_count
    FROM appointments
    WHERE doctor_id = p_doctor_id
      AND appointment_date = p_date
      AND appointment_time = p_time;

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Doctor is already booked at this time.');
    END IF;

    INSERT INTO appointments(patient_id, doctor_id, appointment_date, appointment_time, status)
    VALUES(p_patient_id, p_doctor_id, p_date, p_time, 'Pending');
END;
