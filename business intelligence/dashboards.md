# BI Dashboards — CareConnect

This document describes the dashboards included in CareConnect’s BI module.  
Each dashboard uses underlying SQL views and PL/SQL summaries.

---

## 1. Patient Insights Dashboard
### Features:
- Total registered patients
- New patients (per month)
- Top age groups
- Patient visit frequency
- Patient unpaid balances summary

### Visuals:
- Age distribution bar chart  
- Monthly new patient line chart  
- Outstanding balance donut chart  
- Frequent visitor ranking table  

---

## 2. Appointment Management Dashboard
### Features:
- Daily appointment volume
- No-shows vs Completed
- Doctor appointment load
- Peak hours of the day/week
- Cancellations trend

### Visuals:
- Daily appointment trend line graph  
- Doctor workload heatmap  
- Hourly distribution histogram  
- Status breakdown pie chart  

---

## 3. Doctor Performance Dashboard
### KPIs:
- Average appointments/day
- Average treatment time
- Treatment count per doctor
- Utilization percentage
- Patient feedback (optional future feature)

### Visuals:
- Doctor leaderboard  
- Monthly performance comparison bar chart  
- Treatment productivity indicators  

---

## 4. Treatment Analysis Dashboard
### Displays:
- Most frequent treatment types
- Medication prescription frequency
- Treatment-to-billing pipeline
- Treatment outcomes (if tracked)

### Visuals:
- Top 10 treatment categories  
- Prescription wordcloud  
- Treatment-to-billing funnel chart  

---

## 5. Financial & Billing Dashboard
### KPIs:
- Total revenue (daily/monthly/yearly)
- Outstanding balance
- Paid vs Unpaid bills
- Billing per doctor
- Billing per treatment type

### Visuals:
- Revenue trend line chart  
- Billing status pie chart  
- Outstanding balance tracker  
- Revenue-by-doctor bar graph  

---

## 6. Executive Summary Dashboard
Summary of all KPIs:
- Total patients
- Daily appointments
- Doctor workload
- Revenue summary
- Treatment count
- No-show rate  
