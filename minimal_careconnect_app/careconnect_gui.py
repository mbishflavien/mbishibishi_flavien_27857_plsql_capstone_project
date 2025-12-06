import tkinter as tk
from tkinter import ttk, messagebox
import oracledb
import threading
from datetime import datetime
import sys

# -------- CONFIG --------
DB_USER = "flavien"
DB_PASS = "mypassword"
DB_DSN = "localhost:1521/ORCLPDB"
# ------------------------

# Global connection pool
connection_pool = None

def init_oracle():
    """Initialize connection pool in THIN mode (no Instant Client needed)"""
    global connection_pool
    try:
        # Create connection pool - NO init_oracle_client call needed!
        connection_pool = oracledb.create_pool(
            user=DB_USER,
            password=DB_PASS,
            dsn=DB_DSN,
            min=2,
            max=5,
            increment=1
        )
        print(f"✓ Connected in THIN mode to {DB_DSN}")
        return True
    except Exception as e:
        messagebox.showerror("Connection Error", 
                           f"Failed to connect to Oracle database:\n{str(e)}\n\n"
                           f"Please check:\n"
                           f"1. Database is running\n"
                           f"2. Credentials are correct (User: {DB_USER})\n"
                           f"3. TNS/DSN is correct: {DB_DSN}")
        return False

def get_conn():
    """Get connection from pool"""
    try:
        if connection_pool is None:
            raise Exception("Connection pool not initialized")
        return connection_pool.acquire()
    except Exception as e:
        raise Exception(f"Failed to get database connection: {str(e)}")

def validate_date(date_str):
    """Validate date format YYYY-MM-DD"""
    try:
        datetime.strptime(date_str, '%Y-%m-%d')
        return True
    except ValueError:
        return False

def validate_time(time_str):
    """Validate time format HH:MM"""
    try:
        datetime.strptime(time_str, '%H:%M')
        return True
    except ValueError:
        return False

def run_in_thread(fn, on_success=None, on_error=None):
    """Run database operations in background thread"""
    def worker():
        try:
            res = fn()
            if on_success:
                root.after(0, lambda: on_success(res))
        except Exception as e:
            error_msg = str(e)
            # Extract Oracle error message if present
            if "ORA-" in error_msg:
                try:
                    # Find the ORA- error
                    start = error_msg.index("ORA-")
                    end = error_msg.find("\n", start)
                    if end == -1:
                        end = len(error_msg)
                    error_msg = error_msg[start:end]
                except:
                    pass
            if on_error:
                root.after(0, lambda: on_error(error_msg))
            else:
                root.after(0, lambda: messagebox.showerror("Error", error_msg))
    threading.Thread(target=worker, daemon=True).start()

# ---------- GUI ----------
root = tk.Tk()
root.title("CareConnect - Healthcare Management System")
root.geometry("950x650")

# Initialize Oracle on startup
if not init_oracle():
    root.destroy()
    sys.exit(1)

# Create notebook for tabs
nb = ttk.Notebook(root)
nb.pack(fill="both", expand=True, padx=5, pady=5)

# ------------------- Tab: Register Patient -------------------
tab_reg = ttk.Frame(nb)
nb.add(tab_reg, text="Register Patient")
frm = ttk.LabelFrame(tab_reg, text="Patient Information", padding=15)
frm.pack(fill="x", padx=10, pady=10)

labels = ["First name", "Last name", "Gender", "DOB (YYYY-MM-DD)", 
          "Phone", "Email", "Address"]
entries = {}

for i, lab in enumerate(labels):
    ttk.Label(frm, text=lab + ":").grid(row=i, column=0, sticky="w", pady=5, padx=(0, 10))
    ent = ttk.Entry(frm, width=45)
    ent.grid(row=i, column=1, sticky="ew", pady=5)
    entries[lab] = ent

frm.columnconfigure(1, weight=1)

lbl_result_reg = ttk.Label(tab_reg, text="", foreground="blue")
lbl_result_reg.pack(pady=5)

def do_register():
    data = {k: v.get().strip() for k, v in entries.items()}
    
    if not data["First name"] or not data["Last name"]:
        messagebox.showwarning("Missing Data", "First name and last name are required")
        return
    
    if data["DOB (YYYY-MM-DD)"] and not validate_date(data["DOB (YYYY-MM-DD)"]):
        messagebox.showwarning("Invalid Date", "Date must be in format YYYY-MM-DD")
        return
    
    def task():
        conn = get_conn()
        cur = conn.cursor()
        try:
            out_id = cur.var(int)
            
            dob = None
            if data["DOB (YYYY-MM-DD)"]:
                dob = datetime.strptime(data["DOB (YYYY-MM-DD)"], '%Y-%m-%d')
            
            cur.callproc("careconnect_pkg.register_patient", [
                data["First name"],
                data["Last name"],
                data["Gender"] if data["Gender"] else None,
                dob,
                data["Phone"] if data["Phone"] else None,
                data["Email"] if data["Email"] else None,
                data["Address"] if data["Address"] else None,
                out_id
            ])
            
            new_id = out_id.getvalue()
            return new_id
        finally:
            cur.close()
            conn.close()
    
    def on_ok(res):
        lbl_result_reg.config(text=f"✓ Patient registered successfully! ID: {res}", 
                              foreground="green")
        for e in entries.values():
            e.delete(0, tk.END)
    
    def on_err(err):
        lbl_result_reg.config(text=f"✗ Error: {err}", foreground="red")
    
    lbl_result_reg.config(text="Processing...", foreground="blue")
    run_in_thread(task, on_success=on_ok, on_error=on_err)

ttk.Button(frm, text="Register Patient", command=do_register).grid(
    row=len(labels), column=1, pady=15, sticky="w")

# ------------------- Tab: Schedule Appointment -------------------
tab_sched = ttk.Frame(nb)
nb.add(tab_sched, text="Schedule Appointment")
f2 = ttk.LabelFrame(tab_sched, text="Appointment Details", padding=15)
f2.pack(fill="x", padx=10, pady=10)

ttk.Label(f2, text="Patient ID:").grid(row=0, column=0, sticky="w", pady=5)
sch_pid = ttk.Entry(f2, width=20)
sch_pid.grid(row=0, column=1, pady=5, sticky="w")

ttk.Label(f2, text="Doctor ID:").grid(row=1, column=0, sticky="w", pady=5)
sch_did = ttk.Entry(f2, width=20)
sch_did.grid(row=1, column=1, pady=5, sticky="w")

ttk.Label(f2, text="Date (YYYY-MM-DD):").grid(row=2, column=0, sticky="w", pady=5)
sch_date = ttk.Entry(f2, width=20)
sch_date.grid(row=2, column=1, pady=5, sticky="w")
ttk.Label(f2, text="e.g., 2025-12-15", font=("", 8), foreground="gray").grid(
    row=2, column=2, sticky="w", padx=5)

ttk.Label(f2, text="Time (HH:MM):").grid(row=3, column=0, sticky="w", pady=5)
sch_time = ttk.Entry(f2, width=20)
sch_time.grid(row=3, column=1, pady=5, sticky="w")
ttk.Label(f2, text="e.g., 14:30", font=("", 8), foreground="gray").grid(
    row=3, column=2, sticky="w", padx=5)

lbl_result_sched = ttk.Label(tab_sched, text="", foreground="blue")
lbl_result_sched.pack(pady=5)

def do_schedule():
    if not all([sch_pid.get(), sch_did.get(), sch_date.get(), sch_time.get()]):
        messagebox.showwarning("Missing Data", "All fields are required")
        return
    
    if not validate_date(sch_date.get()):
        messagebox.showwarning("Invalid Date", "Date must be in format YYYY-MM-DD")
        return
    
    if not validate_time(sch_time.get()):
        messagebox.showwarning("Invalid Time", "Time must be in format HH:MM (24-hour)")
        return
    
    def task():
        conn = get_conn()
        cur = conn.cursor()
        try:
            dt = datetime.strptime(sch_date.get(), '%Y-%m-%d')
            cur.callproc("careconnect_pkg.schedule_appointment", [
                int(sch_pid.get()),
                int(sch_did.get()),
                dt,
                sch_time.get()
            ])
            return True
        finally:
            cur.close()
            conn.close()
    
    def on_ok(r):
        lbl_result_sched.config(text="✓ Appointment scheduled successfully!", 
                               foreground="green")
        sch_pid.delete(0, tk.END)
        sch_did.delete(0, tk.END)
        sch_date.delete(0, tk.END)
        sch_time.delete(0, tk.END)
    
    def on_err(e):
        lbl_result_sched.config(text=f"✗ Error: {e}", foreground="red")
    
    lbl_result_sched.config(text="Processing...", foreground="blue")
    run_in_thread(task, on_success=on_ok, on_error=on_err)

ttk.Button(f2, text="Schedule Appointment", command=do_schedule).grid(
    row=4, column=1, pady=15, sticky="w")

# ------------------- Tab: Reschedule -------------------
tab_res = ttk.Frame(nb)
nb.add(tab_res, text="Reschedule Appointment")
f3 = ttk.LabelFrame(tab_res, text="Reschedule Details", padding=15)
f3.pack(fill="x", padx=10, pady=10)

ttk.Label(f3, text="Appointment ID:").grid(row=0, column=0, sticky="w", pady=5)
res_aid = ttk.Entry(f3, width=20)
res_aid.grid(row=0, column=1, pady=5, sticky="w")

ttk.Label(f3, text="New Date (YYYY-MM-DD):").grid(row=1, column=0, sticky="w", pady=5)
res_date = ttk.Entry(f3, width=20)
res_date.grid(row=1, column=1, pady=5, sticky="w")

ttk.Label(f3, text="New Time (HH:MM):").grid(row=2, column=0, sticky="w", pady=5)
res_time = ttk.Entry(f3, width=20)
res_time.grid(row=2, column=1, pady=5, sticky="w")

lbl_result_res = ttk.Label(tab_res, text="", foreground="blue")
lbl_result_res.pack(pady=5)

def do_reschedule():
    if not all([res_aid.get(), res_date.get(), res_time.get()]):
        messagebox.showwarning("Missing Data", "All fields are required")
        return
    
    if not validate_date(res_date.get()):
        messagebox.showwarning("Invalid Date", "Date must be in format YYYY-MM-DD")
        return
    
    if not validate_time(res_time.get()):
        messagebox.showwarning("Invalid Time", "Time must be in format HH:MM")
        return
    
    def task():
        conn = get_conn()
        cur = conn.cursor()
        try:
            dt = datetime.strptime(res_date.get(), '%Y-%m-%d')
            cur.callproc("careconnect_pkg.reschedule_appointment", [
                int(res_aid.get()),
                dt,
                res_time.get()
            ])
            return True
        finally:
            cur.close()
            conn.close()
    
    def on_ok(r):
        lbl_result_res.config(text="✓ Appointment rescheduled successfully!", 
                             foreground="green")
    
    def on_err(e):
        lbl_result_res.config(text=f"✗ Error: {e}", foreground="red")
    
    lbl_result_res.config(text="Processing...", foreground="blue")
    run_in_thread(task, on_success=on_ok, on_error=on_err)

ttk.Button(f3, text="Reschedule", command=do_reschedule).grid(
    row=3, column=1, pady=15, sticky="w")

# ------------------- Tab: Record Treatment -------------------
tab_tr = ttk.Frame(nb)
nb.add(tab_tr, text="Record Treatment")
f4 = ttk.LabelFrame(tab_tr, text="Treatment Details", padding=15)
f4.pack(fill="x", padx=10, pady=10)

ttk.Label(f4, text="Appointment ID:").grid(row=0, column=0, sticky="w", pady=5)
tr_aid = ttk.Entry(f4, width=20)
tr_aid.grid(row=0, column=1, pady=5, sticky="w")

ttk.Label(f4, text="Doctor ID:").grid(row=1, column=0, sticky="w", pady=5)
tr_did = ttk.Entry(f4, width=20)
tr_did.grid(row=1, column=1, pady=5, sticky="w")

ttk.Label(f4, text="Description:").grid(row=2, column=0, sticky="nw", pady=5)
tr_desc = tk.Text(f4, width=50, height=4)
tr_desc.grid(row=2, column=1, pady=5, sticky="ew")

ttk.Label(f4, text="Prescription:").grid(row=3, column=0, sticky="nw", pady=5)
tr_pres = tk.Text(f4, width=50, height=4)
tr_pres.grid(row=3, column=1, pady=5, sticky="ew")

f4.columnconfigure(1, weight=1)

lbl_result_tr = ttk.Label(tab_tr, text="", foreground="blue")
lbl_result_tr.pack(pady=5)

def do_record_treatment():
    if not tr_aid.get() or not tr_did.get():
        messagebox.showwarning("Missing Data", "Appointment ID and Doctor ID are required")
        return
    
    def task():
        conn = get_conn()
        cur = conn.cursor()
        try:
            cur.callproc("careconnect_pkg.record_treatment", [
                int(tr_aid.get()),
                int(tr_did.get()),
                tr_desc.get("1.0", tk.END).strip(),
                tr_pres.get("1.0", tk.END).strip()
            ])
            return True
        finally:
            cur.close()
            conn.close()
    
    def on_ok(r):
        lbl_result_tr.config(text="✓ Treatment recorded successfully!", 
                            foreground="green")
        tr_aid.delete(0, tk.END)
        tr_did.delete(0, tk.END)
        tr_desc.delete("1.0", tk.END)
        tr_pres.delete("1.0", tk.END)
    
    def on_err(e):
        lbl_result_tr.config(text=f"✗ Error: {e}", foreground="red")
    
    lbl_result_tr.config(text="Processing...", foreground="blue")
    run_in_thread(task, on_success=on_ok, on_error=on_err)

ttk.Button(f4, text="Record Treatment", command=do_record_treatment).grid(
    row=4, column=1, pady=15, sticky="w")

# ------------------- Tab: Mark Bill Paid -------------------
tab_bill = ttk.Frame(nb)
nb.add(tab_bill, text="Mark Bill Paid")
f5 = ttk.LabelFrame(tab_bill, text="Billing", padding=15)
f5.pack(fill="x", padx=10, pady=10)

ttk.Label(f5, text="Bill ID:").grid(row=0, column=0, sticky="w", pady=5)
bill_id_entry = ttk.Entry(f5, width=20)
bill_id_entry.grid(row=0, column=1, pady=5, sticky="w")

lbl_result_bill = ttk.Label(tab_bill, text="", foreground="blue")
lbl_result_bill.pack(pady=5)

def do_mark_paid():
    if not bill_id_entry.get():
        messagebox.showwarning("Missing Data", "Bill ID is required")
        return
    
    def task():
        conn = get_conn()
        cur = conn.cursor()
        try:
            cur.callproc("careconnect_pkg.mark_bill_paid", [int(bill_id_entry.get())])
            return True
        finally:
            cur.close()
            conn.close()
    
    def on_ok(r):
        lbl_result_bill.config(text="✓ Bill marked as paid!", foreground="green")
        bill_id_entry.delete(0, tk.END)
    
    def on_err(e):
        lbl_result_bill.config(text=f"✗ Error: {e}", foreground="red")
    
    lbl_result_bill.config(text="Processing...", foreground="blue")
    run_in_thread(task, on_success=on_ok, on_error=on_err)

ttk.Button(f5, text="Mark Paid", command=do_mark_paid).grid(
    row=1, column=1, pady=15, sticky="w")

# ------------------- Tab: Doctor Schedule -------------------
tab_sched_view = ttk.Frame(nb)
nb.add(tab_sched_view, text="Doctor Schedule")
fs = ttk.LabelFrame(tab_sched_view, text="View Schedule", padding=15)
fs.pack(fill="x", padx=10, pady=10)

ttk.Label(fs, text="Doctor ID:").grid(row=0, column=0, sticky="w", pady=5)
ds_doc = ttk.Entry(fs, width=20)
ds_doc.grid(row=0, column=1, pady=5, sticky="w")

ttk.Label(fs, text="Date (YYYY-MM-DD):").grid(row=1, column=0, sticky="w", pady=5)
ds_date = ttk.Entry(fs, width=20)
ds_date.grid(row=1, column=1, pady=5, sticky="w")

frame_txt = ttk.Frame(tab_sched_view)
frame_txt.pack(padx=10, pady=5, fill="both", expand=True)

scrollbar_y = ttk.Scrollbar(frame_txt)
scrollbar_y.pack(side="right", fill="y")

scrollbar_x = ttk.Scrollbar(frame_txt, orient="horizontal")
scrollbar_x.pack(side="bottom", fill="x")

txt_schedule = tk.Text(frame_txt, height=15, wrap="none", 
                       yscrollcommand=scrollbar_y.set,
                       xscrollcommand=scrollbar_x.set)
txt_schedule.pack(side="left", fill="both", expand=True)

scrollbar_y.config(command=txt_schedule.yview)
scrollbar_x.config(command=txt_schedule.xview)

def do_get_schedule():
    if not ds_doc.get() or not ds_date.get():
        messagebox.showwarning("Missing Data", "Doctor ID and date are required")
        return
    
    if not validate_date(ds_date.get()):
        messagebox.showwarning("Invalid Date", "Date must be in format YYYY-MM-DD")
        return
    
    def task():
        conn = get_conn()
        cur = conn.cursor()
        try:
            outcur = conn.cursor()
            dt = datetime.strptime(ds_date.get(), '%Y-%m-%d')
            cur.callproc("careconnect_pkg.get_doctor_schedule", 
                        [int(ds_doc.get()), dt, outcur])
            rows = outcur.fetchall()
            return rows
        finally:
            if 'outcur' in locals():
                outcur.close()
            cur.close()
            conn.close()
    
    def on_ok(rows):
        txt_schedule.delete("1.0", tk.END)
        if not rows:
            txt_schedule.insert(tk.END, "No appointments found for this date.\n")
        else:
            txt_schedule.insert(tk.END, f"{'ID':<8} {'Patient Name':<25} {'Date':<12} {'Time':<8} {'Status':<12}\n")
            txt_schedule.insert(tk.END, "-" * 80 + "\n")
            for r in rows:
                appt_id, name, date, time, status = r
                date_str = date.strftime('%Y-%m-%d') if hasattr(date, 'strftime') else str(date)
                txt_schedule.insert(tk.END, 
                    f"{appt_id:<8} {name:<25} {date_str:<12} {time:<8} {status:<12}\n")
    
    def on_err(e):
        txt_schedule.delete("1.0", tk.END)
        txt_schedule.insert(tk.END, f"Error: {e}\n")
    
    txt_schedule.delete("1.0", tk.END)
    txt_schedule.insert(tk.END, "Loading...\n")
    run_in_thread(task, on_success=on_ok, on_error=on_err)

ttk.Button(fs, text="Get Schedule", command=do_get_schedule).grid(
    row=2, column=1, pady=15, sticky="w")

# ------------------- Tab: Patient Report -------------------
tab_prep = ttk.Frame(nb)
nb.add(tab_prep, text="Patient Report")
fp = ttk.LabelFrame(tab_prep, text="Generate Report", padding=15)
fp.pack(fill="x", padx=10, pady=10)

ttk.Label(fp, text="Patient ID:").grid(row=0, column=0, sticky="w", pady=5)
pr_pid = ttk.Entry(fp, width=20)
pr_pid.grid(row=0, column=1, pady=5, sticky="w")

frame_prep = ttk.Frame(tab_prep)
frame_prep.pack(padx=10, pady=5, fill="both", expand=True)

scrollbar_prep = ttk.Scrollbar(frame_prep)
scrollbar_prep.pack(side="right", fill="y")

txt_prep = tk.Text(frame_prep, height=15, yscrollcommand=scrollbar_prep.set)
txt_prep.pack(side="left", fill="both", expand=True)
scrollbar_prep.config(command=txt_prep.yview)

def do_patient_report():
    if not pr_pid.get():
        messagebox.showwarning("Missing Data", "Patient ID is required")
        return
    
    def task():
        conn = get_conn()
        cur = conn.cursor()
        try:
            outcur = conn.cursor()
            cur.callproc("careconnect_pkg.generate_patient_report", 
                        [int(pr_pid.get()), outcur])
            rows = outcur.fetchall()
            return rows
        finally:
            if 'outcur' in locals():
                outcur.close()
            cur.close()
            conn.close()
    
    def on_ok(rows):
        txt_prep.delete("1.0", tk.END)
        if not rows:
            txt_prep.insert(tk.END, "No data found for this patient.\n")
        else:
            for r in rows:
                pid, name, appts, treats, billed, paid = r
                txt_prep.insert(tk.END, "=" * 60 + "\n")
                txt_prep.insert(tk.END, f"PATIENT REPORT\n")
                txt_prep.insert(tk.END, "=" * 60 + "\n\n")
                txt_prep.insert(tk.END, f"Patient ID:          {pid}\n")
                txt_prep.insert(tk.END, f"Patient Name:        {name}\n")
                txt_prep.insert(tk.END, f"Total Appointments:  {appts}\n")
                txt_prep.insert(tk.END, f"Total Treatments:    {treats}\n")
                txt_prep.insert(tk.END, f"Total Billed:        ${float(billed):.2f}\n")
                txt_prep.insert(tk.END, f"Total Paid:          ${float(paid):.2f}\n")
                txt_prep.insert(tk.END, f"Outstanding:         ${float(billed) - float(paid):.2f}\n")
    
    def on_err(e):
        txt_prep.delete("1.0", tk.END)
        txt_prep.insert(tk.END, f"Error: {e}\n")
    
    txt_prep.delete("1.0", tk.END)
    txt_prep.insert(tk.END, "Loading...\n")
    run_in_thread(task, on_success=on_ok, on_error=on_err)

ttk.Button(fp, text="Generate Report", command=do_patient_report).grid(
    row=1, column=1, pady=15, sticky="w")

# ------------------- Tab: BI Dashboard -------------------
tab_bi = ttk.Frame(nb)
nb.add(tab_bi, text="BI Dashboard")
fb = ttk.LabelFrame(tab_bi, text="Key Performance Indicators", padding=15)
fb.pack(fill="x", padx=10, pady=10)

ttk.Label(fb, text="Doctor ID:").grid(row=0, column=0, sticky="w", pady=5)
bi_doc = ttk.Entry(fb, width=20)
bi_doc.grid(row=0, column=1, pady=5, sticky="w")

ttk.Label(fb, text="Year-Month (YYYY-MM):").grid(row=1, column=0, sticky="w", pady=5)
bi_month = ttk.Entry(fb, width=20)
bi_month.grid(row=1, column=1, pady=5, sticky="w")
bi_month.insert(0, "2025-12")

frame_bi = ttk.Frame(tab_bi)
frame_bi.pack(padx=10, pady=5, fill="both", expand=True)

scrollbar_bi = ttk.Scrollbar(frame_bi)
scrollbar_bi.pack(side="right", fill="y")

txt_bi = tk.Text(frame_bi, height=15, yscrollcommand=scrollbar_bi.set)
txt_bi.pack(side="left", fill="both", expand=True)
scrollbar_bi.config(command=txt_bi.yview)

def do_bi():
    if not bi_doc.get():
        messagebox.showwarning("Missing Data", "Doctor ID is required")
        return
    
    def task():
        conn = get_conn()
        cur = conn.cursor()
        try:
            # Average wait time for 2025
            cur.execute("SELECT careconnect_pkg.avg_wait_time(:1, :2) FROM dual",
                       [datetime(2025, 1, 1), datetime(2025, 12, 31)])
            avg_wait = cur.fetchone()[0]
            
            # Monthly patient load
            month_str = bi_month.get().strip()
            cur.execute("SELECT careconnect_pkg.monthly_patient_load(:1) FROM dual",
                       [month_str])
            month_load = cur.fetchone()[0]
            
            # Doctor performance score
            cur.execute("SELECT careconnect_pkg.doctor_performance_score(:1) FROM dual",
                       [int(bi_doc.get())])
            perf = cur.fetchone()[0]
            
            return avg_wait, month_load, perf, month_str
        finally:
            cur.close()
            conn.close()
    
    def on_ok(res):
        avg_wait, month_load, perf, month_str = res
        txt_bi.delete("1.0", tk.END)
        txt_bi.insert(tk.END, "=" * 60 + "\n")
        txt_bi.insert(tk.END, "BUSINESS INTELLIGENCE DASHBOARD\n")
        txt_bi.insert(tk.END, "=" * 60 + "\n\n")
        txt_bi.insert(tk.END, f"Average Wait Time (2025):        {float(avg_wait):.2f} minutes\n\n")
        txt_bi.insert(tk.END, f"Monthly Patient Load ({month_str}):   {month_load} patients\n\n")
        txt_bi.insert(tk.END, f"Doctor Performance Score:        {float(perf):.2f}/100\n\n")
        txt_bi.insert(tk.END, "-" * 60 + "\n")
        txt_bi.insert(tk.END, "Performance Score Calculation:\n")
        txt_bi.insert(tk.END, "  - 50% based on average patient rating (0-5 stars)\n")
        txt_bi.insert(tk.END, "  - 50% based on number of treatments performed\n")
    
    def on_err(e):
        txt_bi.delete("1.0", tk.END)
        txt_bi.insert(tk.END, f"Error: {e}\n")
    
    txt_bi.delete("1.0", tk.END)
    txt_bi.insert(tk.END, "Loading...\n")
    run_in_thread(task, on_success=on_ok, on_error=on_err)

ttk.Button(fb, text="Run BI Analysis", command=do_bi).grid(
    row=2, column=1, pady=15, sticky="w")

# ------------------- Status bar -------------------
status_bar = ttk.Label(root, text="Connected to database (Thin Mode)", relief=tk.SUNKEN, anchor=tk.W)
status_bar.pack(side=tk.BOTTOM, fill=tk.X)

# Cleanup on exit
def on_closing():
    if connection_pool:
        connection_pool.close()
    root.destroy()

root.protocol("WM_DELETE_WINDOW", on_closing)

# ------------------- Start mainloop -------------------
root.mainloop()