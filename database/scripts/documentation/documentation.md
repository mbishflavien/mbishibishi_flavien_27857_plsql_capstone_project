# CareConnect — Database & PL/SQL System

## CareConnect is a modular healthcare information system designed to manage clinical workflows, automate scheduling logic, enforce business rules, and support analytics for better decision-making.

### This project includes database schema design, PL/SQL business logic, audit control, and BI-ready analytical functions.

### 1. Project Structure Overview
careconnect/
│
├── database/
│   ├── scripts/
│     ├── table_creation.sql
│     ├── data_insertion.sql
│     ├── triggers.sql
│     ├── package.sql
│     └── procedures.sql

### 2. What This System Does
#### Core Features

-Patient registration & doctor management
-Smart appointment scheduling with business rules
-Automated holiday + weekday restriction trigger
-Treatment & billing workflow
-Feedback & patient satisfaction tracking
-Full audit logging of allowed + denied operations
-BI-ready reporting functions (performance, revenue, load)

#### PL/SQL Logic Layer

**Includes:**

-A full package (careconnect_pkg)
-Standalone procedures
-Analytical functions
-Enforcement triggers

### 3. SQL Scripts — Description

### table_creation.sql

Defines all database tables:

**PATIENTS**
**DOCTORS**
**APPOINTMENTS**
**TREATMENTS**
**BILLING**
**FEEDBACK**
**HOLIDAYS**
**AUDIT_LOG**

Includes:

-Primary keys
-Foreign keys
-Default values
-Constraints (NOT NULL, CHECK)

### data_insertion.sql

Contains dummy data for each table:

-12+ patients
-12+ doctors
-Corresponding appointments
-Treatments & billing info
-Feedback entries
-National holidays
-Perfect for testing triggers, BI queries, and procedures.

### triggers.sql

Implements system-wide automated rules:

Key Trigger: trg_secure_insert_appointments

Blocks appointments on weekdays (Mon–Fri)
Allows only weekend scheduling (Sat–Sun)
Blocks holiday scheduling
Writes every attempt into AUDIT_LOG

**Trigger ensures:**

-Allowed inserts = logged
-Denied inserts = logged with reason

**Other triggers include:**
-trg_audit_delete
-trg_audit_update
-trg_auto_billing

### package.sql

**Defines the main system API:**

*Procedures:*

-schedule_appointment
-reschedule_appointment
-get_doctor_schedule
-register_patient
-record_treatment
-mark_bill_paid
-generate_patient_report
-log_audit

*Functions (BI-ready):*

-monthly_patient_load
-doctor_performance_score
-avg_wait_time
-calculate_total_unpaid


The package separates business logic from raw SQL tables.

#### procedures.sql

*Additional standalone procedures for testing:*
They serve in:
-Logging
-Maintenance updates
-Data cleanup
-Utility operations

### 4. Business Intelligence Layer
Analytics Delivered:

-Doctor revenue
-Repeat-patient percentage
-Monthly appointment load
-Treatment count per doctor
-Patient satisfaction scoring
-Service quality trend lines
-Billing performance (paid vs unpaid)

**Example KPI Query:**

SELECT d.doctor_id,
       d.first_name || ' ' || d.last_name AS doctor_name,
       SUM(b.amount) AS revenue
FROM billing b
JOIN treatments t ON t.treatment_id = b.treatment_id
JOIN doctors d ON d.doctor_id = t.doctor_id
WHERE b.status = 'Paid'
GROUP BY d.doctor_id, doctor_name;

### 5. Architecture Summary
#### Layers
**1. Operational Database Layer**

-Relational data model
-Optimized for OLTP
-Core entities + relationships

**2. Business Logic Layer (PL/SQL)**

-Triggers
-Packages
-Procedures
-Validation rules

**3. Audit & Security Layer**

-Centralized AUDIT_LOG
-Monitors every restricted action
-Helps meet compliance standards

**4. Analytics / BI Layer**

-KPI functions
-Aggregations

*Dashboards (optional integration)*

### 6. How to Run the System
**Step 1 — Connect**
Username: flavien
Password: *********** *(provided upon request)*
Host: localhost
Port: 1521
Service: ORCLPDB

**Step 2 — Execute Scripts (in order)**
-table_creation.sql
-triggers.sql
-package.sql
-procedures.sql
-data_insertion.sql

### 7. Author
**MBISHIBISHI Flavien**