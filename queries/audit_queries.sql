--1. Top Users With Denied Operations
SELECT ATTEMPT_BY,
       COUNT(*) AS denied_attempts
FROM audit_log
WHERE STATUS = 'DENIED'
GROUP BY ATTEMPT_BY
ORDER BY denied_attempts DESC;

--2. Appointments Blocked by Trigger
SELECT *
FROM audit_log
WHERE TABLE_NAME = 'APPOINTMENTS'
  AND STATUS = 'DENIED'
ORDER BY ATTEMPT_DATE DESC;

--3. Weekend Insert Attempts

SELECT AUDIT_ID,
       ATTEMPT_BY,
       ATTEMPT_DATE,
       STATUS,
       REASON
FROM audit_log
WHERE LOWER(REASON) LIKE '%weekend%'
ORDER BY ATTEMPT_DATE DESC;

--4. Holiday Violations
SELECT AUDIT_ID,
       ATTEMPT_DATE,
       ATTEMPT_BY,
       REASON
FROM audit_log
WHERE LOWER(REASON) LIKE '%holiday%'
ORDER BY ATTEMPT_DATE DESC;

--5. Detailed Security Report (Everything in One View)
SELECT
    a.AUDIT_ID,
    a.TABLE_NAME,
    a.OPERATION,
    a.STATUS,
    a.REASON,
    a.ATTEMPT_BY,
    a.ATTEMPT_DATE,
    (
        SELECT COUNT(*)
        FROM audit_log b
        WHERE b.ATTEMPT_BY = a.ATTEMPT_BY
          AND b.STATUS = 'DENIED'
    ) AS total_denied_by_user
FROM audit_log a
ORDER BY a.ATTEMPT_DATE DESC;