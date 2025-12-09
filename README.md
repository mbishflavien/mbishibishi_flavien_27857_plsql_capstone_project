#  CareConnect – Healthcare Information System

[![Oracle](https://img.shields.io/badge/Oracle-PL%2FSQL-red?style=flat&logo=oracle)](https://www.oracle.com/)
[![Database](https://img.shields.io/badge/Database-Healthcare-blue)](https://github.com/mbishflavien/mbishibishi_flavien_27857_plsql_capstone_project)
[![Status](https://img.shields.io/badge/Status-Complete-success)](https://github.com/mbishflavien/mbishibishi_flavien_27857_plsql_capstone_project)

> A complete healthcare information system built using Oracle PL/SQL demonstrating enterprise-level database design, business logic implementation, and data integrity management.

**Developed by:** MBISHIBISHI Flavien  
**Student ID:** 27857  
**Project Type:** PL/SQL Capstone Project
**Project Name:** Careconnect

---

##  Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Project Structure](#-project-structure)
- [Database Schema](#️-database-schema)
- [Core Components](#-core-components)
- [Installation & Setup](#-installation--setup)
- [Usage Examples](#-usage-examples)
- [Analytics & Reporting](#-analytics--reporting)
- [Documentation](#-documentation)
- [Technologies](#-technologies)
- [Author](#-author)

---

##  Overview

**CareConnect** is a fully functional healthcare management system implementing industry-standard database practices. This project showcases:

- **Modular PL/SQL Programming:** Organized packages and procedures
- **Transactional Logic:** ACID-compliant operations
- **Data Integrity:** Comprehensive constraints and validations
- **Automated Business Rules:** Intelligent triggers
- **Audit Trail:** Complete change tracking
- **Analytics & Reporting:** Healthcare KPIs and insights

The system simulates real-world hospital operations including patient registration, appointment scheduling, billing management, and comprehensive audit logging.

---

##  Key Features

###  Healthcare Modules

- **Patient Management** – Registration, updates, demographic tracking
- **Doctor & Staff Records** – Professional profiles and specializations
- **Appointment System** – Scheduling with conflict detection
- **Billing & Payments** – Invoice generation and payment tracking
- **Department Management** – Organizational structure
- **Service Catalog** – Medical services and pricing
- **Audit Logging** – Automated change tracking for compliance

###  Security & Compliance

- Automated audit trails for sensitive data
- Data validation at database level
- Role-based access considerations
- HIPAA-aligned data handling practices

###  Business Intelligence

- Healthcare KPIs and metrics
- Revenue analytics
- Appointment statistics
- Patient demographics
- Service utilization reports

---

##  Project Structure

```
mbishibishi_flavien_27857_plsql_capstone_project/
│
├── 📁 database/
│   └── 📁 scripts/
│       ├── 📄 table_creation.sql      # Schema definition
│       ├── 📄 data_insertion.sql      # Sample data
│       ├── 📄 procedures.sql          # Business logic procedures
│       ├── 📄 package.sql             # Organized PL/SQL packages
│       ├── 📄 triggers.sql            # Automated rules & validations
│       └── 📁 documentation/          # Technical specs
│
├── 📁 queries/                        # Analytics & reporting queries
├── 📁 documentation/                  # Project documentation & reports
├── 📁 screenshots/
│   └── 📁 plsqlfinalproject/         # Visual documentation
└── 📁 minimal_careconnect_app/       # Frontend prototype

```

---

##  Database Schema

### Core Tables

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `PATIENTS` | Patient demographics & medical records | PK, unique identifiers, DOB validation |
| `DOCTORS` | Healthcare provider information | Specialization, department links |
| `APPOINTMENTS` | Scheduling & patient-doctor links | Time slot management, status tracking |
| `BILLING` | Financial transactions & invoices | Auto-calculation, payment status |
| `DEPARTMENTS` | Hospital organizational units | Hierarchy, specialization grouping |
| `AUDIT_LOG` | Change tracking for compliance | Timestamp, user, old/new values |

### Database Features

-  **Normalized Design** (3NF compliance)
-  **Referential Integrity** (Foreign key constraints)
-  **Auto-increment Sequences** for primary keys
-  **Check Constraints** for data validation
-  **Indexes** for performance optimization

** Schema File:** `database/scripts/table_creation.sql`

---

##  Core Components

### 1. PL/SQL Package (`package.sql`)

A modular API providing organized access to system functionality:

#### **Patient Management API**
```sql
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
```

#### **Appointment Management API**
```sql
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

```

#### **Billing API**
```sql

-- Mark bill as paid
PROCEDURE mark_bill_paid(p_billing_id NUMBER);

```

#### **Utility Functions**
- Date formatting and validation
- Data lookup helpers
- Input sanitization
- Error handling wrappers

---

### 2. Business Logic Procedures (`procedures.sql`)

Standalone procedures for specific operations:
- Complex appointment rescheduling
- Bulk data operations
- Report generation
- Data migration utilities

---

### 3. Intelligent Triggers (`triggers.sql`)

| Trigger | Event | Purpose |
|---------|-------|---------|
| `trg_auto_billing` | AFTER INSERT on treatments | Automatically generates billing record when treatment is added |
| `trg_audit_update` | AFTER UPDATE on appointments | Logs appointment status changes for compliance |
| `trg_audit_delete` | BEFORE DELETE on appointments | Records appointment deletions in audit log |
| `trg_secure_insert_appointments` | BEFORE INSERT on appointments | Enforces business rules: blocks weekday/holiday appointments, allows weekends only |

#### Detailed Trigger Functionality

**1. Auto-Billing Trigger (`trg_auto_billing`)**
```sql
-- Automatically creates a billing record when treatment is added
-- Default amount: 30,000 RWF (configurable)
-- Initial status: 'Unpaid'
```
- Ensures every treatment generates a corresponding bill
- Eliminates manual billing entry errors
- Maintains data consistency between treatments and billing

**2. Appointment Update Audit (`trg_audit_update`)**
```sql
-- Tracks all appointment status changes
-- Records: old status → new status
-- Maintains complete change history
```
- Compliance with healthcare record-keeping requirements
- Enables tracking of appointment lifecycle
- Supports dispute resolution and reporting

**3. Appointment Deletion Audit (`trg_audit_delete`)**
```sql
-- Logs deletion attempts before they occur
-- Preserves record of deleted appointments
-- Captures appointment ID and deletion timestamp
```
- Prevents data loss without audit trail
- Supports regulatory compliance
- Enables recovery of deleted records

**4. Smart Appointment Security (`trg_secure_insert_appointments`)**
```sql
-- Advanced business rule enforcement:
--  BLOCKS: Holiday appointments
--  BLOCKS: Weekday appointments (Mon-Fri)
--  ALLOWS: Weekend appointments only (Sat-Sun)
```

**Security Features:**
- Uses `PRAGMA AUTONOMOUS_TRANSACTION` for reliable audit logging
- Cross-references `holidays` table for public holiday validation
- Provides detailed denial reasons in audit log
- Raises custom application errors with meaningful messages

**Business Logic:**
- Day calculation using `TO_CHAR(:NEW.appointment_date, 'D')`
- Holiday detection via database lookup
- Weekday check (days 2-6 = Monday-Friday)
- Weekend allowance (days 1,7 = Sunday, Saturday)

**Key Benefits:**
-  Enforce complex business rules at database level
-  Automatic data quality checks
-  Comprehensive compliance audit trails
-  Prevent data anomalies and policy violations
-  Autonomous transaction logging for reliability
-  User-friendly error messages for rule violations


---

### 4. Sample Data (`data_insertion.sql`)

Realistic test data including:
- 50+ sample patients
- 20+ doctors across specializations
- Multiple departments
- Various appointment scenarios
- Billing records with different statuses
- Service catalog entries

---

##  Installation & Setup

### Prerequisites

- **Oracle Database** 11g or higher (19c recommended)
- **Oracle SQL Developer** or **SQL*Plus**
- Basic understanding of PL/SQL

### Step-by-Step Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/mbishflavien/mbishibishi_flavien_27857_plsql_capstone_project.git
   cd mbishibishi_flavien_27857_plsql_capstone_project
   ```

2. **Connect to Oracle Database:**
   ```bash
   sqlplus username/password@database
   ```

3. **Execute scripts in order:**
   ```sql
   -- Step 1: Create schema
   @database/scripts/table_creation.sql

   -- Step 2: Insert sample data
   @database/scripts/data_insertion.sql

   -- Step 3: Create procedures
   @database/scripts/procedures.sql

   -- Step 4: Create package
   @database/scripts/package.sql

   -- Step 5: Create triggers
   @database/scripts/triggers.sql
   ```

4. **Verify installation:**
   ```sql
   -- Check tables
   SELECT table_name FROM user_tables;

   -- Verify data
   SELECT COUNT(*) FROM PATIENTS;
   SELECT COUNT(*) FROM APPOINTMENTS;

   -- Test package
   SELECT careconnect_pkg.get_patient_age(1) FROM DUAL;
   ```

---

##  Analytics & Reporting

### Available Queries (`queries/` folder)

#### **1. Healthcare KPIs**
- Total patient registrations
- Appointment completion rates
- Average wait times
- Doctor utilization rates

#### **2. Revenue Analytics**
```sql
-- Monthly revenue report
SELECT 
    TO_CHAR(billing_date, 'YYYY-MM') AS month,
    COUNT(*) AS total_invoices,
    SUM(amount) AS total_revenue,
    AVG(amount) AS average_invoice
FROM BILLING
WHERE payment_status = 'PAID'
GROUP BY TO_CHAR(billing_date, 'YYYY-MM')
ORDER BY month DESC;
```

#### **3. Appointment Statistics**
- Appointments by department
- Peak appointment hours
- Cancellation rates
- No-show analysis

#### **4. Patient Demographics**
- Age distribution
- Gender breakdown
- Geographic analysis
- Patient retention metrics

#### **5. Service Utilization**
```sql
-- Top 10 most requested services
SELECT 
    s.service_name,
    COUNT(b.billing_id) AS times_used,
    SUM(b.amount) AS total_revenue
FROM SERVICES s
JOIN BILLING b ON s.service_id = b.service_id
GROUP BY s.service_name
ORDER BY times_used DESC
FETCH FIRST 10 ROWS ONLY;
```

**📸 Query Screenshots:** Available in `screenshots/plsqlfinalproject/`

---

##  Minimal CareConnect App

A lightweight frontend prototype demonstrating system integration created using **Python Tkinter**

**Location:** `minimal_careconnect_app/`

**Features:**
- Patient registration form
- Appointment booking interface
- Billing dashboard
- Basic reporting views

This demonstrates how a real-world application could connect to the PL/SQL backend through database APIs.

---

##  Documentation

Comprehensive documentation available in `documentation/`:

- **System Architecture** – Database design & ERD diagrams
- **Technical Specifications** – Table structures, relationships
- **User Workflows** – Process flows & use cases
- **Query Documentation** – Detailed query explanations
- **Screenshots** – Visual demonstrations of functionality
- **Test Cases** – Validation & testing results
- **Submission Reports** – Academic project deliverables

---

##  Technologies

| Category | Technology |
|----------|-----------|
| **Database** | Oracle Database 21c |
| **Language** | PL/SQL, SQL, and Python|
| **Tools** | Oracle SQL Developer |
| **Methodology** | Agile Development, Database-First Design |
| **Standards** | ACID Compliance, 3NF Normalization |

---

##  Learning Outcomes

This project demonstrates proficiency in:

-  **Database Design** – Normalized schemas, ERD modeling
-  **PL/SQL Programming** – Packages, procedures, functions
-  **Trigger Development** – Business rule automation
-  **Transaction Management** – COMMIT, ROLLBACK, SAVEPOINT
-  **Error Handling** – Exception management
-  **Performance Optimization** – Indexing, query tuning
-  **Data Integrity** – Constraints, validations
-  **Security** – Audit logging, access control
-  **Business Intelligence** – Analytics, reporting

---

##  Contact

**MBISHIBISHI Flavien**  
Software Engineering Student | PL/SQL Developer  
Kigali, Rwanda  

[![GitHub](https://img.shields.io/badge/GitHub-mbishflavien-181717?style=flat&logo=github)](https://github.com/mbishflavien)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=flat&logo=linkedin)](https://www.linkedin.com/in/mbishibishi-flavien-4120a52b8/)
[![Email](https://img.shields.io/badge/Email-Contact-D14836?style=flat&logo=gmail)](mailto:flavmbish@gmail.com)

---

##  License

This project is submitted as part of academic requirements for educational purposes.  
© 2024 MBISHIBISHI Flavien. All rights reserved.

---

##  Acknowledgments

- Course instructor for guidance, specifically Mr. MANIRAGUHA Eric
- Oracle documentation and PL/SQL community
- Healthcare domain experts for requirements insights
- Fellow students for collaborative learning

---

<div align="center">


*Developed with dedication as a capstone project demonstrating enterprise-level database development skills.*

</div>
