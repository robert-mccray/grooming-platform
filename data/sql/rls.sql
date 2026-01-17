/* =========================================================
   Grooming Platform - Row Level Security (Facility Scoping)
   Strategy:
   - API sets SESSION_CONTEXT('facility_id') per request
   - RLS filters rows where table.facility_id = session facility_id
   Notes:
   - Requires tables to have facility_id column (audit has it; core tables mostly do)
   - Some tables without facility_id (e.g., core.vendors, core.services) are global by design.
   ========================================================= */

-- 1) Create a schema for security objects (optional but clean)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sec') EXEC('CREATE SCHEMA sec');
GO

-- 2) Helper function: get facility_id from session context
--    Returns NULL if not set; policy will then block access.
CREATE OR ALTER FUNCTION sec.fn_session_facility_id()
RETURNS UNIQUEIDENTIFIER
WITH SCHEMABINDING
AS
BEGIN
  DECLARE @fid UNIQUEIDENTIFIER;

  -- SESSION_CONTEXT returns sql_variant; TRY_CONVERT safely handles invalid values
  SET @fid = TRY_CONVERT(UNIQUEIDENTIFIER, SESSION_CONTEXT(N'facility_id'));
  RETURN @fid;
END;
GO

-- 3) Predicate function used by RLS
--    If session facility_id is NULL, no rows match -> access denied by default.
CREATE OR ALTER FUNCTION sec.fn_facility_predicate(@facility_id UNIQUEIDENTIFIER)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
  SELECT 1 AS fn_access_result
  WHERE @facility_id = sec.fn_session_facility_id();
GO

/* =========================================================
   4) Security Policy
   Apply to facility-scoped tables. 
   (Do NOT apply to global lookup tables like core.services)
   ========================================================= */

-- If policy exists, drop & recreate for idempotent runs
IF EXISTS (SELECT 1 FROM sys.security_policies WHERE name = 'FacilityRlsPolicy')
BEGIN
  DROP SECURITY POLICY sec.FacilityRlsPolicy;
END
GO

CREATE SECURITY POLICY sec.FacilityRlsPolicy
ADD FILTER PREDICATE sec.fn_facility_predicate(facility_id) ON core.facilities,
ADD FILTER PREDICATE sec.fn_facility_predicate(facility_id) ON core.staff_users,
ADD FILTER PREDICATE sec.fn_facility_predicate(facility_id) ON core.facility_vendors,
ADD FILTER PREDICATE sec.fn_facility_predicate(facility_id) ON core.residents,
ADD FILTER PREDICATE sec.fn_facility_predicate(facility_id) ON core.appointments,
ADD FILTER PREDICATE sec.fn_facility_predicate(facility_id) ON core.approval_events,
ADD FILTER PREDICATE sec.fn_facility_predicate(facility_id) ON audit.audit_events
WITH (STATE = ON);
GO

/* =========================================================
   5) Usage pattern (what your API must do)
   You must set the session context after opening the SQL connection.
   Example T-SQL the API executes:
     EXEC sys.sp_set_session_context @key=N'facility_id', @value=@FacilityId;
   Optional: set read_only=1 so it can’t be overwritten mid-session:
     EXEC sys.sp_set_session_context @key=N'facility_id', @value=@FacilityId, @read_only=1;

   For local testing:
     EXEC sys.sp_set_session_context N'facility_id', '00000000-0000-0000-0000-000000000001', 1;
     SELECT * FROM core.appointments;  -- only that facility’s rows appear
   ========================================================= */
