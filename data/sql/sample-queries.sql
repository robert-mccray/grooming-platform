SET NOCOUNT ON;

-- Tables list
SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name;

-- Confirm reporting view
SELECT TOP 20 * FROM core.vw_appointments_reporting ORDER BY start_time DESC;

-- Confirm audit append-only works (this should error)
BEGIN TRY
  UPDATE audit.audit_events SET event_type='NOPE';
END TRY
BEGIN CATCH
  SELECT ERROR_MESSAGE() AS expected_error;
END CATCH;
