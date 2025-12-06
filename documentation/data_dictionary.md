# CareConnect — Data Dictionary

This document describes all tables, columns, data types, and constraints used in the CareConnect database system.

---

## 1. PATIENTS
| Column | Type | Description |
|--------|-------|-------------|
| patient_id | NUMBER PK | Unique identifier for each patient |
| first_name | VARCHAR2(50) | Patient’s first name |
| last_name | VARCHAR2(50) | Patient’s last name |
| gender | VARCHAR2(10) | Male/Female |
| dob | DATE | Date of birth |
| phone | VARCHAR2(20) | Phone number |
| email | VARCHAR2(100) | Email address |
| address | VARCHAR2(200) | Physical address |
| created_at | DATE | Default SYSDATE |

---

## 2. DOCTORS
| Column | Type | Description |
|--------|--------|-------------|
| doctor_id | NUMBER PK | Unique doctor ID |
| first_name | VARCHAR2(50) | Doctor first name |
| last_name | VARCHAR2(50) | Doctor last name |
| specialization | VARCHAR2(100) | Medical specialty |
| phone | VARCHAR2(20) | Contact number |
| email | VARCHAR2(100) | Work email |
| created_at | DATE | Timestamp |

---

## 3. APPOINTMENTS
| Column | Type | Description |
|--------|--------|-------------|
| appointment_id | NUMBER PK | Unique appointment ID |
| patient_id | NUMBER FK | References PATIENTS |
| doctor_id | NUMBER FK | References DOCTORS |
| appointment_date | DATE | Appointment date |
| appointment_time | VARCHAR2(10) | HH24:MI |
| status | VARCHAR2(20) | Pending / Completed / Canceled |
| reason | VARCHAR2(200) | Reason for appointment |
| created_at | DATE | Timestamp |

---

## 4. TREATMENTS
| Column | Type | Description |
|---------|--------|-------------|
| treatment_id | NUMBER PK | Unique treatment ID |
| appointment_id | NUMBER FK | References APPOINTMENTS |
| doctor_id | NUMBER FK | References DOCTORS |
| description | VARCHAR2(200) | Treatment details |
| prescription | VARCHAR2(200) | Medication |
| treatment_date | DATE | Auto SYSDATE |

---

## 5. BILLING
| Column | Type | Description |
|---------|---------|-------------|
| bill_id | NUMBER PK | Unique billing record |
| treatment_id | NUMBER FK | References TREATMENTS |
| amount | NUMBER(10,2) | Total cost |
| status | VARCHAR2(20) | Paid / Unpaid |
| payment_date | DATE | If paid |
| created_at | DATE | Timestamp |

---

## 6. AUDIT_LOG
| Column | Type | Description |
|--------|---------|-------------|
| log_id | NUMBER PK | Unique log entry |
| table_name | VARCHAR2(50) | Table affected |
| operation | VARCHAR2(50) | INSERT / UPDATE / DELETE / ATTEMPT |
| record_id | NUMBER | Record modified |
| old_value | CLOB | Before change |
| new_value | CLOB | After change |
| attempt_by | VARCHAR2(50) | Username |
| attempt_date | DATE | Timestamp |
| status | VARCHAR2(20) | ALLOWED / DENIED |
| reason | VARCHAR2(200) | Explanation |
