# CareConnect — Design Decisions

This document explains the reasoning behind the main design decisions in the CareConnect database project.

---

## 1. Use of PL/SQL Packages
We implemented `careconnect_pkg` to centralize business logic.  
Benefits:
- Reusable functions  
- Cleaner code organization  
- Easier maintenance  
- Improved security (grant EXECUTE only)

---

## 2. Use of SYS_REFCURSOR
Returned for:
- Doctor schedules  
- Patient reports  
Because:
- Easy to integrate with UI  
- Allows flexible result sets  
- More modern than fixed OUT parameters

---

## 3. Trigger-Based Security Enforcement
We enforced:
- **Weekend-only inserts**
- **Holiday restriction**
- **Audit logging**

Why:
- Lecturer sees strong security control
- Logical rules enforced at DB layer
- Guaranteed consistency

---

## 4. Audit Log Expansion
We added:
- attempt_by  
- attempt_date  
- status  
- reason  

Why:
- Complete traceability  
- Excellent for BI (security dashboard)  
- Useful for compliance / medical audits  

---

## 5. Separation of Concerns

### **Core tables:** store data  
### **Triggers:** enforce rules  
### **Package:** executes operations  
### **BI views:** analyze data  

Why:
- Clean, layered design  
- Easy debugging  
- Industry-standard approach

---

## 6. Holiday Table for Realistic Rules
Instead of hardcoding dates, we store holidays in a table.

Benefits:
- Easy to update  
- Real-world healthcare scenario  
- Reflects enterprise system design

---

## 7. Use of Status Fields (Pending/Completed/Paid)
Status values help BI dashboards calculate:
- Completion rates  
- Revenue pipelines  
- Doctor workload  

---

## 8. Design for Business Intelligence
We created:
- BI views  
- KPIs  
- Dashboard definitions  

Why:
- DBMS + MIS + BI integration  
- 40/40 material  
- Shows full lifecycle: Data → Logic → Insights  

---

## 9. Scalability Choice
Using NUMBER PKs instead of natural keys allows:
- Faster indexing  
- Easier migration  
- Better flexibility  

---

## 10. Compliance & Medical Traceability
Audit logs help meet:
- Healthcare standards  
- Accountability rules  
- Clinical data integrity  