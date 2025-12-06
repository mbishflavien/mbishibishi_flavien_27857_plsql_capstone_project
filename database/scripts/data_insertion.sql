-- Inserting into PATIENTS.

INSERT INTO patients (first_name, last_name, gender, dob, phone, email, address)
VALUES ('John', 'Mbogo', 'Male', DATE '1995-06-12', '0788001122', 'john@example.com', 'Kigali');

INSERT INTO patients (first_name, last_name, gender, dob, phone, email, address)
VALUES ('Amina', 'Uwase', 'Female', DATE '1999-02-20', '0788554433', 'amina@gmail.com', 'Kicukiro');

INSERT INTO patients (first_name, last_name, gender, dob, phone, email, address)
VALUES ('Eric', 'Nshuti', 'Male', DATE '2001-09-09', '0788223344', 'ericn@gmail.com', 'Gasabo');

INSERT INTO patients (patient_id, first_name, last_name, gender, dob, phone, email, address)
VALUES (4,  'Alice', 'Nkurunziza', 'Female', DATE '1996-04-10', '0789001010', 'alice.nk@example.com', 'Kicukiro');

INSERT INTO patients VALUES (5,  'Brian', 'Uwizeye', 'Male',   DATE '1994-08-15', '0789002020', 'brian.uw@example.com', 'Remera');
INSERT INTO patients VALUES (6,  'Chantal', 'Mukamana', 'Female', DATE '1999-12-01', '0789003030', 'chantal.mk@example.com', 'Kimihurura');
INSERT INTO patients VALUES (7,  'David', 'Habimana', 'Male', DATE '1992-03-10', '0789004040', 'david.hb@example.com', 'Nyamirambo');
INSERT INTO patients VALUES (8,  'Esther', 'Iradukunda', 'Female', DATE '1988-07-29', '0789005050', 'esther.ik@example.com', 'Kacyiru');
INSERT INTO patients VALUES (9,  'Frank', 'Mugisha', 'Male', DATE '1997-06-20', '0789006060', 'frank.mg@example.com', 'Kanombe');
INSERT INTO patients VALUES (10, 'Grace', 'Mukantabana', 'Female', DATE '1993-05-05', '0789007070', 'grace.mb@example.com', 'Gisozi');
INSERT INTO patients VALUES (11, 'Henry', 'Twagirimana', 'Male', DATE '1985-01-21', '0789008080', 'henry.tw@example.com', 'Gikondo');
INSERT INTO patients VALUES (12, 'Irene', 'Akingeneye', 'Female', DATE '1998-11-29', '0789009090', 'irene.ak@example.com', 'Nyarutarama');

--Inserting into DOCTORS

INSERT INTO doctors (first_name, last_name, specialization, phone)
VALUES ('Alice', 'Mukamana', 'Cardiology', '0722001122');

INSERT INTO doctors (first_name, last_name, specialization, phone)
VALUES ('David', 'Karangwa', 'Pediatrics', '0722991144');

INSERT INTO doctors (first_name, last_name, specialization, phone)
VALUES ('Sophia', 'Niyonsaba', 'General Medicine', '0722998811');

INSERT INTO doctors (doctor_id, first_name, last_name, specialization, phone)
VALUES (4, 'Linda', 'Uwase', 'Cardiology', '0722101101');

INSERT INTO doctors VALUES (5, 'Paul', 'Ntambara', 'Pediatrics', '0722102202');
INSERT INTO doctors VALUES (6, 'Samuel', 'Bizimana', 'Orthopedics', '0722103303');
INSERT INTO doctors VALUES (7, 'Patricia', 'Mukandayisenga', 'Dermatology', '0722104404');
INSERT INTO doctors VALUES (8, 'Joseph', 'Ndayishimiye', 'General Medicine', '0722105505');
INSERT INTO doctors VALUES (9, 'Rebecca', 'Mukashyaka', 'Gynecology', '0722106606');
INSERT INTO doctors VALUES (10, 'Arthur', 'Habiyaremye', 'Neurology', '0722107707');
INSERT INTO doctors VALUES (11, 'Divine', 'Uwimbabazi', 'ENT', '0722108808');
INSERT INTO doctors VALUES (12, 'Patrick', 'Karangwa', 'Radiology', '0722109909');


--Inserting into APPOINTMENTS

INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status)
VALUES (1, 1, DATE '2025-01-20', '09:00', 'Pending');

INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status)
VALUES (2, 2, DATE '2025-01-21', '10:30', 'Pending');

INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status)
VALUES (3, 3, DATE '2025-01-20', '14:00', 'Pending');

INSERT INTO appointments VALUES (4, 4, 4,  DATE '2025-02-15', '09:00', 'Pending');   
INSERT INTO appointments VALUES (5, 5, 5,  DATE '2025-02-16', '10:00', 'Completed');  
INSERT INTO appointments VALUES (6, 6, 6,  DATE '2025-02-22', '11:30', 'Completed');   
INSERT INTO appointments VALUES (7, 7, 7,  DATE '2025-02-23', '14:00', 'Cancelled');  
INSERT INTO appointments VALUES (8, 8, 8,  DATE '2025-03-01', '15:00', 'Pending');     
INSERT INTO appointments VALUES (9, 9, 9,  DATE '2025-03-02', '08:30', 'Completed');   
INSERT INTO appointments VALUES (10, 10, 10, DATE '2025-03-08', '09:45', 'Pending');   
INSERT INTO appointments VALUES (11, 11, 11, DATE '2025-03-09', '16:00', 'Completed'); 
INSERT INTO appointments VALUES (12, 12, 12, DATE '2025-03-15', '13:20', 'Pending');  

--Inserting into TREATMENTS

INSERT INTO treatments (appointment_id, doctor_id, description, prescription, treatment_date)
VALUES (1, 1, 'Chest pain evaluation', 'Painkiller 200mg', SYSDATE);

INSERT INTO treatments (appointment_id, doctor_id, description, prescription, treatment_date)
VALUES (2, 2, 'Flu symptoms', 'Vitamin C + Antibiotics', SYSDATE);

INSERT INTO treatments (appointment_id, doctor_id, description, prescription, treatment_date)
VALUES (3, 3, 'Routine checkup', 'No prescription', SYSDATE);

INSERT INTO treatments VALUES (4, 4, 4, 'Blood pressure check', 'Aspirin 75mg', DATE '2025-02-15');
INSERT INTO treatments VALUES (5, 5, 5, 'Pediatric flu', 'Syrup + Vitamin C', DATE '2025-02-16');
INSERT INTO treatments VALUES (6, 6, 6, 'Fracture screening', 'Ibuprofen', DATE '2025-02-22');
INSERT INTO treatments VALUES (7, 7, 7, 'Skin allergy', 'Hydrocortisone', DATE '2025-02-23');
INSERT INTO treatments VALUES (8, 8, 8, 'General consultation', 'Paracetamol', DATE '2025-03-01');
INSERT INTO treatments VALUES (9, 9, 9, 'Prenatal care', 'Folic Acid', DATE '2025-03-02');
INSERT INTO treatments VALUES (10, 10, 10, 'Neurological test', 'Neuro Aid', DATE '2025-03-08');
INSERT INTO treatments VALUES (11, 11, 11, 'ENT cleaning', 'Nasal Spray', DATE '2025-03-09');
INSERT INTO treatments VALUES (12, 12, 12, 'Radiology imaging', 'None', DATE '2025-03-15');

--Inserting into BILLING

INSERT INTO billing (treatment_id, amount, status, payment_date)
VALUES (1, 50000, 'Paid', SYSDATE);

INSERT INTO billing (treatment_id, amount, status, payment_date)
VALUES (2, 30000, 'Unpaid', NULL);

INSERT INTO billing (treatment_id, amount, status, payment_date)
VALUES (3, 20000, 'Paid', SYSDATE);

INSERT INTO billing VALUES (4, 4, 15000, 'Paid', DATE '2025-02-15');
INSERT INTO billing VALUES (5, 5, 22000, 'Paid', DATE '2025-02-16');
INSERT INTO billing VALUES (6, 6, 18000, 'Unpaid', NULL);
INSERT INTO billing VALUES (7, 7, 25000, 'Paid', DATE '2025-02-23');
INSERT INTO billing VALUES (8, 8, 12000, 'Unpaid', NULL);
INSERT INTO billing VALUES (9, 9, 20000, 'Paid', DATE '2025-03-02');
INSERT INTO billing VALUES (10, 10, 30000, 'Paid', DATE '2025-03-08');
INSERT INTO billing VALUES (11, 11, 17000, 'Unpaid', NULL);
INSERT INTO billing VALUES (12, 12, 45000, 'Paid', DATE '2025-03-15');

--Inserting into FEEDBACK

INSERT INTO feedback (patient_id, doctor_id, rating, comments, feedback_date)
VALUES (1, 1, 5, 'Very professional doctor.', SYSDATE);

INSERT INTO feedback (patient_id, doctor_id, rating, comments, feedback_date)
VALUES (2, 2, 4, 'Good service but long waiting time.', SYSDATE);

INSERT INTO feedback VALUES (4, 4, 4, 5, 'Very helpful doctor', SYSDATE - 15);
INSERT INTO feedback VALUES (5, 5, 5, 4, 'Good service', SYSDATE - 14);
INSERT INTO feedback VALUES (6, 6, 6, 3, 'Average experience', SYSDATE - 13);
INSERT INTO feedback VALUES (7, 7, 7, 5, 'Excellent care', SYSDATE - 12);
INSERT INTO feedback VALUES (8, 8, 8, 2, 'Long waiting time', SYSDATE - 11);
INSERT INTO feedback VALUES (9, 9, 9, 4, 'Friendly staff', SYSDATE - 10);
INSERT INTO feedback VALUES (10, 10, 10, 5, 'Doctor explained well', SYSDATE - 9);
INSERT INTO feedback VALUES (11, 11, 11, 1, 'Poor experience', SYSDATE - 8);
INSERT INTO feedback VALUES (12, 12, 12, 5, 'Very satisfied', SYSDATE - 7);

--Inserting into HOLIDAYS

INSERT INTO holidays VALUES (DATE '2025-01-01', 'New Year');
INSERT INTO holidays VALUES (DATE '2025-07-01', 'Independence Day');
INSERT INTO holidays VALUES (DATE '2025-12-25', 'Christmas Day');
INSERT INTO holidays VALUES (DATE '2025-02-01', 'Heroes Day');
INSERT INTO holidays VALUES (DATE '2025-07-04', 'Liberation Day');

COMMIT;