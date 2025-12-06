# CareConnect — System Architecture

CareConnect is built as a modular clinical data management system. It uses a layered architecture that separates the operational database, PL/SQL logic, audit/security layer, and BI analytics layer.

---

## 1. High-Level Architecture Diagram

**Layers:**

1. **Operational Database Layer**
   - Core relational tables (Patients, Doctors, Appointments, Treatments, Billing)
   - Enforces referential integrity
   - Supports transactional processing

2. **Application Logic Layer (PL/SQL)**
   - careconnect_pkg (procedures/functions)
   - Triggers (security, audit, automation)
   - Business rules (weekend inserts, holiday restrictions)

3. **Audit & Security Layer**
   - Audit log for all operations
   - Trigger-based access restrictions
   - Error-handling and controlled exceptions

4. **BI & Analytics Layer**
   - SQL Views for BI
   - Dashboards (Appointments, Revenue, Patients, Doctors)
   - KPI calculations

---

## 2. Technology Stack
| Component | Technology |
|-----------|------------|
| Database | Oracle 19c / Oracle SQL Developer |
| Programming | PL/SQL (procedures, functions, triggers) |
| Logging | Audit tables + triggers |
| BI Layer | SQL Views + external dashboards (Power BI, Excel) |
| Security | Database roles, triggers, exception handling |

---

## 3. Data Flow Overview

### **Step 1: Data Capture**
Patients → Appointments → Treatments → Billing

### **Step 2: Business Logic Execution**
- Appointment scheduling validation  
- Treatment recording  
- Auto-billing  
- Weekend/holiday trigger restrictions  

### **Step 3: Logging & Auditing**
Every insert attempt is logged with:
- User  
- Timestamp  
- Status (ALLOWED/DENIED)  
- Reason  

### **Step 4: BI Analytics**
Views aggregate:
- Appointment trends  
- Doctor performance  
- Revenue metrics  
- Patient demographics  

---

## 4. Security Architecture
- Restricted INSERTs via BEFORE INSERT trigger  
- Holiday calendar enforcement  
- Weekday restrictions  
- Role-based access (e.g., `GRANT EXECUTE ON careconnect_pkg TO app_user`)  
- All business actions logged  

---

## 5. Integration Architecture
CareConnect can connect with:
- Web UI
- Mobile app
- External BI tools
- Government reporting systems (future)

---

## 6. Scalability
The architecture supports:
- Thousands of appointments daily  
- Multiple doctors  
- BI queries via materialized views (optional future work)  
