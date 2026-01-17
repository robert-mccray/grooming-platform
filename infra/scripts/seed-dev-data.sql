-- =========================================================
-- DEV Seed Data (safe to re-run)
-- =========================================================

SET NOCOUNT ON;

DECLARE @facility_id UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000001';
DECLARE @vendor_id   UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000010';
DECLARE @svc_haircut UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000100';
DECLARE @svc_nails   UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000101';

DECLARE @resident_1 UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000001001';
DECLARE @resident_2 UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000001002';

DECLARE @appt_1 UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000010001';
DECLARE @appt_2 UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000010002';

-- Facility
IF NOT EXISTS (SELECT 1 FROM core.facilities WHERE facility_id = @facility_id)
INSERT INTO core.facilities (facility_id, name, timezone, status)
VALUES (@facility_id, 'Houston Assisted Living 01', 'America/Chicago', 'active');

-- Vendor
IF NOT EXISTS (SELECT 1 FROM core.vendors WHERE vendor_id = @vendor_id)
INSERT INTO core.vendors (vendor_id, legal_name, phone, email, license_number, status)
VALUES (@vendor_id, 'Kev''s Clippers', '555-0101', 'kev@example.com', 'TX-CLIP-123', 'active');

-- Services (global)
IF NOT EXISTS (SELECT 1 FROM core.services WHERE service_id = @svc_haircut)
INSERT INTO core.services (service_id, service_name, default_duration_minutes, requires_staff_presence, is_active)
VALUES (@svc_haircut, 'Haircut', 30, 0, 1);

IF NOT EXISTS (SELECT 1 FROM core.services WHERE service_id = @svc_nails)
INSERT INTO core.services (service_id, service_name, default_duration_minutes, requires_staff_presence, is_active)
VALUES (@svc_nails, 'Nails', 45, 1, 1);

-- Facility-Vendor mapping
IF NOT EXISTS (SELECT 1 FROM core.facility_vendors WHERE facility_id=@facility_id AND vendor_id=@vendor_id)
INSERT INTO core.facility_vendors (facility_vendor_id, facility_id, vendor_id, onboarding_status, start_date)
VALUES (NEWID(), @facility_id, @vendor_id, 'approved', CAST(GETUTCDATE() AS date));

-- Residents
IF NOT EXISTS (SELECT 1 FROM core.residents WHERE resident_id = @resident_1)
INSERT INTO core.residents (resident_id, facility_id, external_resident_key, first_name, last_name, date_of_birth, room, status)
VALUES (@resident_1, @facility_id, 'R-10001', 'James', 'Turner', '1942-06-11', '112A', 'active');

IF NOT EXISTS (SELECT 1 FROM core.residents WHERE resident_id = @resident_2)
INSERT INTO core.residents (resident_id, facility_id, external_resident_key, first_name, last_name, date_of_birth, room, status)
VALUES (@resident_2, @facility_id, 'R-10002', 'Martha', 'Reed', '1938-09-04', '114C', 'active');

-- Appointments
IF NOT EXISTS (SELECT 1 FROM core.appointments WHERE appointment_id = @appt_1)
INSERT INTO core.appointments
(appointment_id, facility_id, resident_id, vendor_id, service_id, start_time, end_time, status, requested_by_role, requested_by_user_id)
VALUES
(@appt_1, @facility_id, @resident_1, @vendor_id, @svc_haircut,
 DATEADD(hour, 2, SYSUTCDATETIME()), DATEADD(minute, 30, DATEADD(hour, 2, SYSUTCDATETIME())),
 'requested', 'staff', NULL);

IF NOT EXISTS (SELECT 1 FROM core.appointments WHERE appointment_id = @appt_2)
INSERT INTO core.appointments
(appointment_id, facility_id, resident_id, vendor_id, service_id, start_time, end_time, status, requested_by_role, requested_by_user_id)
VALUES
(@appt_2, @facility_id, @resident_2, @vendor_id, @svc_nails,
 DATEADD(day, 1, DATEADD(hour, 4, SYSUTCDATETIME())), DATEADD(minute, 45, DATEADD(day, 1, DATEADD(hour, 4, SYSUTCDATETIME()))),
 'approved', 'facility_admin', NULL);

-- Approval event
INSERT INTO core.approval_events (approval_event_id, appointment_id, facility_id, action, actor_role, actor_user_id, reason)
VALUES (NEWID(), @appt_2, @facility_id, 'approved', 'facility_admin', NULL, 'Approved for vendor schedule');

-- Audit events (append-only)
INSERT INTO audit.audit_events (audit_event_id, facility_id, appointment_id, event_type, actor_role, actor_user_id, target_type, target_id, metadata_json)
VALUES
(NEWID(), @facility_id, @appt_1, 'APPOINTMENT_CREATED', 'staff', NULL, 'Appointment', @appt_1, N'{"source":"seed"}'),
(NEWID(), @facility_id, @appt_2, 'STATUS_CHANGED', 'facility_admin', NULL, 'Appointment', @appt_2, N'{"from":"requested","to":"approved","source":"seed"}');

PRINT '✅ Seed data applied.';
