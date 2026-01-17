SET NOCOUNT ON;

-- Uniqueness per facility for staff email
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_staff_users_facility_email')
CREATE UNIQUE INDEX UX_staff_users_facility_email
  ON core.staff_users(facility_id, email);

-- Many-to-many uniqueness
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_facility_vendors_facility_vendor')
CREATE UNIQUE INDEX UX_facility_vendors_facility_vendor
  ON core.facility_vendors(facility_id, vendor_id);

-- Residents browse pattern
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_residents_facility_last_first')
CREATE INDEX IX_residents_facility_last_first
  ON core.residents(facility_id, last_name, first_name);

-- Services name unique
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_services_name')
CREATE UNIQUE INDEX UX_services_name
  ON core.services(service_name);

-- Schedule hot paths
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_appointments_facility_start')
CREATE INDEX IX_appointments_facility_start
  ON core.appointments(facility_id, start_time)
  INCLUDE (status, vendor_id, resident_id, service_id, end_time);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_appointments_vendor_start')
CREATE INDEX IX_appointments_vendor_start
  ON core.appointments(vendor_id, start_time)
  INCLUDE (status, facility_id, resident_id, service_id, end_time);

-- Approval history
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_approval_events_appt_time')
CREATE INDEX IX_approval_events_appt_time
  ON core.approval_events(appointment_id, occurred_at DESC);

-- Audit by facility/time
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_audit_events_facility_time')
CREATE INDEX IX_audit_events_facility_time
  ON audit.audit_events(facility_id, occurred_at DESC)
  INCLUDE (event_type, actor_role, actor_user_id, appointment_id, target_type, target_id);

-- Filtered "active schedule"
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_appointments_active_schedule')
CREATE INDEX IX_appointments_active_schedule
  ON core.appointments(facility_id, start_time)
  INCLUDE (vendor_id, resident_id, service_id, status, end_time)
  WHERE status IN ('requested','approved');
