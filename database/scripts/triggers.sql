-- 1. Auto-generate Bill When Treatment Is Added
CREATE OR REPLACE TRIGGER trg_auto_billing
AFTER INSERT ON treatments
FOR EACH ROW
BEGIN
    INSERT INTO billing(treatment_id, amount, status)
    VALUES(:NEW.treatment_id, 30000, 'Unpaid');
END;
/


-- You can change the amount or even compute based on treatment type.

-- 2. Audit Log Trigger — UPDATE
CREATE OR REPLACE TRIGGER trg_audit_update
AFTER UPDATE ON appointments
FOR EACH ROW
BEGIN
    INSERT INTO audit_log(table_name, operation, record_id, old_value, new_value)
    VALUES(
        'APPOINTMENTS',
        'UPDATE',
        :OLD.appointment_id,
        'Old Status: ' || :OLD.status,
        'New Status: ' || :NEW.status
    );
END;
/

-- 3. Audit Trigger — DELETE on APPOINTMENTS
CREATE OR REPLACE TRIGGER trg_audit_delete
BEFORE DELETE ON appointments
FOR EACH ROW
BEGIN
    INSERT INTO audit_log(table_name, operation, record_id, old_value)
    VALUES(
        'APPOINTMENTS',
        'DELETE',
        :OLD.appointment_id,
        'Deleted Appointment'
    );
END;
/
-- 4. Security trigger - Block or Allow insert
CREATE OR REPLACE TRIGGER trg_secure_insert_appointments
BEFORE INSERT ON appointments
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION;

    v_day   NUMBER;
    v_holiday_count NUMBER;
    v_status VARCHAR2(20);
    v_reason VARCHAR2(200);
BEGIN
    -- Day of the week (1=Sunday … 7=Saturday)
    v_day := TO_CHAR(:NEW.appointment_date, 'D');

    -- Check if the date is a holiday
    SELECT COUNT(*) INTO v_holiday_count
    FROM holidays
    WHERE TRUNC(holiday_date) = TRUNC(:NEW.appointment_date);

    -- Rule 1: Holiday → DENIED
    IF v_holiday_count > 0 THEN
        v_status := 'DENIED';
        v_reason := 'INSERT blocked because the date is a holiday.';

        INSERT INTO audit_log (
            table_name, operation, changed_at, attempt_by,
            attempt_date, status, reason
        ) VALUES (
            'APPOINTMENTS', 'INSERT ATTEMPT', SYSDATE, USER,
            SYSDATE, v_status, v_reason
        );

        COMMIT; 

        RAISE_APPLICATION_ERROR(-20901, 'INSERT denied: Holiday date.');
    END IF;

    -- Rule 2: Weekday (Mon–Fri) → DENIED
    IF v_day BETWEEN 2 AND 6 THEN
        v_status := 'DENIED';
        v_reason := 'INSERT blocked because it is a weekday.';

        INSERT INTO audit_log (
            table_name, operation, changed_at, attempt_by,
            attempt_date, status, reason
        ) VALUES (
            'APPOINTMENTS', 'INSERT ATTEMPT', SYSDATE, USER,
            SYSDATE, v_status, v_reason
        );

        COMMIT;

        RAISE_APPLICATION_ERROR(-20902, 'INSERT denied: Weekday not allowed.');
    END IF;

    -- Rule 3: Weekend → ALLOWED
    v_status := 'ALLOWED';
    v_reason := 'INSERT allowed because it is a weekend.';

    INSERT INTO audit_log (
        table_name, operation, changed_at, attempt_by,
        attempt_date, status, reason
    ) VALUES (
        'APPOINTMENTS', 'INSERT ATTEMPT', SYSDATE, USER,
        SYSDATE, v_status, v_reason
    );

    COMMIT;

END;
/
