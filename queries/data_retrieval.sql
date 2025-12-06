------------------------------------------------------------
-- CareConnect Project
-- File: data_retrieval.sql
-- Purpose: Basic data retrieval queries for demo + testing
------------------------------------------------------------

-- 1. Get all patients
SELECT patient_id, first_name, last_name, gender, dob, phone
FROM patients
ORDER BY patient_id;

-- 2. Get all doctors with specialization
SELECT doctor_id, first_name, last_name, specialization
FROM doctors
ORDER BY doctor_id;

-- 3. Get upcoming appointments
SELECT a.appointment_id,
       p.first_name || ' ' || p.last_name AS patient_name,
       d.first_name || ' ' || d.last_name AS doctor_name,
       a.appointment_date,
       a.appointment_time,
       a.status
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
WHERE a.appointment_date >= SYSDATE
ORDER BY a.appointment_date, a.appointment_time;

-- 4. Get completed appointments
SELECT *
FROM appointments
WHERE status = 'Completed'
ORDER BY appointment_date DESC;

-- 5. Get treatments with appointment and doctor details
SELECT t.treatment_id,
       p.first_name || ' ' || p.last_name AS patient_name,
       d.first_name || ' ' || d.last_name AS doctor_name,
       t.description,
       t.prescription,
       t.treatment_date
FROM treatments t
JOIN appointments a ON t.appointment_id = a.appointment_id
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON t.doctor_id = d.doctor_id;

-- 6. Get billing details
SELECT b.bill_id,
       t.treatment_id,
       b.amount,
       b.status,
       b.payment_date
FROM billing b
JOIN treatments t ON b.treatment_id = t.treatment_id
ORDER BY b.bill_id;
