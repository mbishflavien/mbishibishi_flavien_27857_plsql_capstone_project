# KPI Definitions — CareConnect

KPIs help measure performance, patient satisfaction, revenue, and operational efficiency.  
Each KPI below includes definition, formula, and data source.

---

## 1. Appointment KPIs

### **1.1 Daily Appointments**
**Definition:** Total appointments scheduled for a given date.  
**Formula:** COUNT(appointments.appointment_id)  
**Source:** appointments table  

---

### **1.2 Appointment Completion Rate**
**Definition:** Percentage of completed appointments vs scheduled.  
**Formula:**  
(COUNT(status='Completed') / COUNT(*)) * 100  

---

### **1.3 No-Show Rate**
**Definition:** Percent of missed appointments.  
**Formula:**  
(COUNT(status='No-Show') / COUNT(*)) * 100  

---

## 2. Patient KPIs

### **2.1 Monthly New Patients**
**Formula:** COUNT(patients WHERE registration_date IN current month)

---

### **2.2 Active Patients**
**Formula:** COUNT(DISTINCT patient_id FROM appointments where date in last 12 months)

---

### **2.3 Patient Retention Rate**
**Formula:**  
(Returning Patients / Total Patients) * 100  

---

## 3. Doctor KPIs

### **3.1 Doctor Utilization**
**Formula:**  
(Total appointments per doctor / Total available slots) * 100  

---

### **3.2 Treatments per Doctor**
**Formula:** COUNT(treatment_id) GROUP BY doctor_id  

---

### **3.3 Revenue per Doctor**
**Formula:** SUM(billing.amount) grouped by doctor

---

## 4. Financial KPIs

### **4.1 Total Revenue**
SUM(billing.amount WHERE status='Paid')

---

### **4.2 Outstanding Balance**
SUM(billing.amount WHERE status='Unpaid')

---

### **4.3 Billing Conversion Rate**
**Definition:** Percentage of treatments that result in a paid bill.  
**Formula:**  
(Paid Bills / Total Bills) * 100  

---

## 5. Treatment KPIs

### **5.1 Treatment Volume**
COUNT(treatment_id)

---

### **5.2 Most Frequent Treatment Type**
MODE(description)

---

### **5.3 Prescription Frequency**
COUNT(prescription) grouped by medication name  

---

## 6. Executive KPIs (Top-level)

| KPI | Description |
|------|-------------|
| Total Patients | Current patient count |
| Daily Visits | Number of appointments today |
| Total Revenue | SUM of paid bills |
| Outstanding Debt | Total unpaid balance |
| Doctor Load | Percentage utilization |
| Avg Treatment/Doctor | Treatments performed per doctor |
