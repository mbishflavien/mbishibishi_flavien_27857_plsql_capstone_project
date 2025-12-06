--   SECTION 1 — APPOINTMENT ANALYTICS

-- 1.1 Daily appointment volume
SELECT appointment_date,
       COUNT(*) AS total_appointments
FROM appointments
GROUP BY appointment_date
ORDER BY appointment_date;

-- 1.2 Weekly appointment trend (Mon–Sun)
SELECT TO_CHAR(appointment_date, 'IW') AS iso_week,
       COUNT(*) AS weekly_appointments
FROM appointments
GROUP BY TO_CHAR(appointment_date, 'IW')
ORDER BY iso_week;

-- 1.3 Monthly appointment trend
SELECT TO_CHAR(appointment_date, 'YYYY-MM') AS month,
       COUNT(*) AS total_appointments
FROM appointments
GROUP BY TO_CHAR(appointment_date, 'YYYY-MM')
ORDER BY month;

-- 1.4 Appointments by status (Pending / Completed / Cancelled)
SELECT status, COUNT(*) AS total
FROM appointments
GROUP BY status;

-- 1.5 No-show rate (if used)
SELECT 
    ROUND(
        (SUM(CASE WHEN status = 'No-Show' THEN 1 END) / COUNT(*)) * 100,
    2) AS no_show_rate
FROM appointments;

-- 1.6 Peak daily hours of appointments
SELECT appointment_time,
       COUNT(*) AS frequency
FROM appointments
GROUP BY appointment_time
ORDER BY frequency DESC;


--   SECTION 2 — DOCTOR PERFORMANCE ANALYTICS

-- 2.1 Treatments per doctor
SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name,
       COUNT(t.treatment_id) AS total_treatments
FROM doctors d
LEFT JOIN treatments t ON d.doctor_id = t.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY total_treatments DESC;

-- 2.2 Doctor appointment load
SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name,
       COUNT(a.appointment_id) AS total_appointments
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY total_appointments DESC;

-- 2.3 Doctor utilization rate (percentage)
-- Formula: appointments / total slots * 100
-- (Assuming 20 slots per day for demonstration)
SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name,
       ROUND((COUNT(a.appointment_id) / 20) * 100, 2) AS utilization_rate
FROM doctors d
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, d.first_name, d.last_name;


--   SECTION 3 — PATIENT ANALYTICS

-- 3.1 Monthly new patients
SELECT TO_CHAR(created_at, 'YYYY-MM') AS month,
       COUNT(*) AS new_patients
FROM patients
GROUP BY TO_CHAR(created_at, 'YYYY-MM')
ORDER BY month;

-- 3.2 Active patients in last 12 months
SELECT COUNT(DISTINCT patient_id) AS active_patients
FROM appointments
WHERE appointment_date >= ADD_MONTHS(SYSDATE, -12);

-- 3.3 Frequent visitors (Top 10)
SELECT p.patient_id,
       p.first_name || ' ' || p.last_name AS full_name,
       COUNT(a.appointment_id) AS total_visits
FROM patients p
JOIN appointments a ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY total_visits DESC
FETCH FIRST 10 ROWS ONLY;

-- 3.4 Patient unpaid balance summary
SELECT p.patient_id,
       p.first_name || ' ' || p.last_name AS full_name,
       NVL(SUM(b.amount), 0) AS total_unpaid
FROM patients p
LEFT JOIN appointments a ON p.patient_id = a.patient_id
LEFT JOIN treatments t ON a.appointment_id = t.appointment_id
LEFT JOIN billing b ON t.treatment_id = b.treatment_id
WHERE b.status = 'Unpaid'
GROUP BY p.patient_id, p.first_name, p.last_name
ORDER BY total_unpaid DESC;


--   SECTION 4 — TREATMENT ANALYTICS

-- 4.1 Treatment volume per month
SELECT TO_CHAR(treatment_date, 'YYYY-MM') AS month,
       COUNT(*) AS total_treatments
FROM treatments
GROUP BY TO_CHAR(treatment_date, 'YYYY-MM')
ORDER BY month;

-- 4.2 Most common treatment types
SELECT description,
       COUNT(*) AS frequency
FROM treatments
GROUP BY description
ORDER BY frequency DESC;

-- 4.3 Most prescribed medications
SELECT prescription,
       COUNT(*) AS count_prescribed
FROM treatments
WHERE prescription IS NOT NULL
GROUP BY prescription
ORDER BY count_prescribed DESC;


--   SECTION 5 — FINANCIAL ANALYTICS

-- 5.1 Monthly revenue (paid only)
SELECT TO_CHAR(payment_date, 'YYYY-MM') AS month,
       SUM(amount) AS revenue
FROM billing
WHERE status = 'Paid'
GROUP BY TO_CHAR(payment_date, 'YYYY-MM')
ORDER BY month;

-- 5.2 Outstanding balance (global)
SELECT SUM(amount) AS total_outstanding
FROM billing
WHERE status = 'Unpaid';

-- 5.3 Revenue by doctor
SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name,
       SUM(b.amount) AS revenue_generated
FROM doctors d
JOIN treatments t ON d.doctor_id = t.doctor_id
JOIN billing b ON t.treatment_id = b.treatment_id
WHERE b.status = 'Paid'
GROUP BY d.doctor_id, d.first_name, d.last_name
ORDER BY revenue_generated DESC;

-- 5.4 Revenue per treatment type
SELECT t.description AS treatment_type,
       SUM(b.amount) AS total_revenue
FROM treatments t
JOIN billing b ON t.treatment_id = b.treatment_id
WHERE b.status = 'Paid'
GROUP BY t.description
ORDER BY total_revenue DESC;


--   SECTION 6 — EXECUTIVE SUMMARY KPIs

-- KPI: Total Patients
SELECT COUNT(*) AS total_patients FROM patients;

-- KPI: Total Revenue
SELECT SUM(amount) AS total_revenue
FROM billing
WHERE status = 'Paid';

-- KPI: Total Outstanding
SELECT SUM(amount) AS outstanding_balance
FROM billing
WHERE status = 'Unpaid';

-- KPI: Daily appointments (today)
SELECT COUNT(*)
FROM appointments
WHERE TRUNC(appointment_date) = TRUNC(SYSDATE);

-- KPI: Total treatments
SELECT COUNT(*) AS total_treatments
FROM treatments;
