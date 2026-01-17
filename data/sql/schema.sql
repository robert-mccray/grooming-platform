/* =========================================================
   Grooming Platform - Azure SQL OLTP Schema (Minimal)
   ========================================================= */

SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'core') EXEC('CREATE SCHEMA core');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'audit') EXEC('CREATE SCHEMA audit');
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'sec') EXEC('CREATE SCHEMA sec');

-- ---------- core.facilities ----------
IF OBJECT_ID('core.facilities','U') IS NULL
CREATE TABLE core.facilities (
  facility_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_facilities PRIMARY KEY,
  name NVARCHAR(200) NOT NULL,
  timezone NVARCHAR(64) NOT NULL CONSTRAINT DF_facilities_timezone DEFAULT ('America/Chicago'),
  status NVARCHAR(30) NOT NULL CONSTRAINT DF_facilities_status DEFAULT ('active'),
  created_at DATETIME2(3) NOT NULL CONSTRAINT DF_facilities_created DEFAULT (SYSUTCDATETIME())
);

-- ---------- core.staff_users ----------
IF OBJECT_ID('core.staff_users','U') IS NULL
CREATE TABLE core.staff_users (
  user_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_staff_users PRIMARY KEY,
  facility_id UNIQUEIDENTIFIER NOT NULL,
  display_name NVARCHAR(200) NOT NULL,
  email NVARCHAR(320) NOT NULL,
  role NVARCHAR(40) NOT NULL,
  status NVARCHAR(30) NOT NULL CONSTRAINT DF_staff_users_status DEFAULT ('active'),
  created_at DATETIME2(3) NOT NULL CONSTRAINT DF_staff_users_created DEFAULT (SYSUTCDATETIME()),
  CONSTRAINT FK_staff_users_facility FOREIGN KEY (facility_id) REFERENCES core.facilities(facility_id)
);

-- ---------- core.vendors (global) ----------
IF OBJECT_ID('core.vendors','U') IS NULL
CREATE TABLE core.vendors (
  vendor_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_vendors PRIMARY KEY,
  legal_name NVARCHAR(200) NOT NULL,
  phone NVARCHAR(30) NULL,
  email NVARCHAR(320) NULL,
  license_number NVARCHAR(80) NULL,
  status NVARCHAR(30) NOT NULL CONSTRAINT DF_vendors_status DEFAULT ('active'),
  created_at DATETIME2(3) NOT NULL CONSTRAINT DF_vendors_created DEFAULT (SYSUTCDATETIME())
);

-- ---------- core.facility_vendors ----------
IF OBJECT_ID('core.facility_vendors','U') IS NULL
CREATE TABLE core.facility_vendors (
  facility_vendor_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_facility_vendors PRIMARY KEY,
  facility_id UNIQUEIDENTIFIER NOT NULL,
  vendor_id UNIQUEIDENTIFIER NOT NULL,
  onboarding_status NVARCHAR(30) NOT NULL CONSTRAINT DF_facility_vendors_onboarding DEFAULT ('pending'),
  start_date DATE NULL,
  end_date DATE NULL,
  created_at DATETIME2(3) NOT NULL CONSTRAINT DF_facility_vendors_created DEFAULT (SYSUTCDATETIME()),
  CONSTRAINT FK_facility_vendors_facility FOREIGN KEY (facility_id) REFERENCES core.facilities(facility_id),
  CONSTRAINT FK_facility_vendors_vendor FOREIGN KEY (vendor_id) REFERENCES core.vendors(vendor_id)
);

-- ---------- core.residents ----------
IF OBJECT_ID('core.residents','U') IS NULL
CREATE TABLE core.residents (
  resident_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_residents PRIMARY KEY,
  facility_id UNIQUEIDENTIFIER NOT NULL,
  external_resident_key NVARCHAR(120) NULL,
  first_name NVARCHAR(120) NOT NULL,
  last_name NVARCHAR(120) NOT NULL,
  date_of_birth DATE NULL,
  room NVARCHAR(40) NULL,
  status NVARCHAR(30) NOT NULL CONSTRAINT DF_residents_status DEFAULT ('active'),
  created_at DATETIME2(3) NOT NULL CONSTRAINT DF_residents_created DEFAULT (SYSUTCDATETIME()),
  CONSTRAINT FK_residents_facility FOREIGN KEY (facility_id) REFERENCES core.facilities(facility_id)
);

-- ---------- core.services (global) ----------
IF OBJECT_ID('core.services','U') IS NULL
CREATE TABLE core.services (
  service_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_services PRIMARY KEY,
  service_name NVARCHAR(120) NOT NULL,
  default_duration_minutes INT NOT NULL CONSTRAINT DF_services_duration DEFAULT (30),
  requires_staff_presence BIT NOT NULL CONSTRAINT DF_services_staff_presence DEFAULT (0),
  is_active BIT NOT NULL CONSTRAINT DF_services_active DEFAULT (1),
  created_at DATETIME2(3) NOT NULL CONSTRAINT DF_services_created DEFAULT (SYSUTCDATETIME())
);

-- ---------- core.appointments ----------
IF OBJECT_ID('core.appointments','U') IS NULL
CREATE TABLE core.appointments (
  appointment_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_appointments PRIMARY KEY,
  facility_id UNIQUEIDENTIFIER NOT NULL,
  resident_id UNIQUEIDENTIFIER NOT NULL,
  vendor_id UNIQUEIDENTIFIER NOT NULL,
  service_id UNIQUEIDENTIFIER NOT NULL,
  start_time DATETIME2(3) NOT NULL,
  end_time   DATETIME2(3) NOT NULL,
  status NVARCHAR(30) NOT NULL,
  requested_by_role NVARCHAR(30) NOT NULL,
  requested_by_user_id UNIQUEIDENTIFIER NULL,
  created_at DATETIME2(3) NOT NULL CONSTRAINT DF_appointments_created DEFAULT (SYSUTCDATETIME()),
  updated_at DATETIME2(3) NOT NULL CONSTRAINT DF_appointments_updated DEFAULT (SYSUTCDATETIME()),
  CONSTRAINT FK_appointments_facility FOREIGN KEY (facility_id) REFERENCES core.facilities(facility_id),
  CONSTRAINT FK_appointments_resident FOREIGN KEY (resident_id) REFERENCES core.residents(resident_id),
  CONSTRAINT FK_appointments_vendor FOREIGN KEY (vendor_id) REFERENCES core.vendors(vendor_id),
  CONSTRAINT FK_appointments_service FOREIGN KEY (service_id) REFERENCES core.services(service_id),
  CONSTRAINT CK_appointments_time CHECK (end_time > start_time)
);

-- ---------- core.approval_events ----------
IF OBJECT_ID('core.approval_events','U') IS NULL
CREATE TABLE core.approval_events (
  approval_event_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_approval_events PRIMARY KEY,
  appointment_id UNIQUEIDENTIFIER NOT NULL,
  facility_id UNIQUEIDENTIFIER NOT NULL,
  action NVARCHAR(30) NOT NULL,
  actor_role NVARCHAR(30) NOT NULL,
  actor_user_id UNIQUEIDENTIFIER NULL,
  reason NVARCHAR(400) NULL,
  occurred_at DATETIME2(3) NOT NULL CONSTRAINT DF_approval_events_occurred DEFAULT (SYSUTCDATETIME()),
  CONSTRAINT FK_approval_events_appointment FOREIGN KEY (appointment_id) REFERENCES core.appointments(appointment_id),
  CONSTRAINT FK_approval_events_facility FOREIGN KEY (facility_id) REFERENCES core.facilities(facility_id)
);

-- ---------- audit.audit_events (append-only) ----------
IF OBJECT_ID('audit.audit_events','U') IS NULL
CREATE TABLE audit.audit_events (
  audit_event_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_audit_events PRIMARY KEY,
  facility_id UNIQUEIDENTIFIER NOT NULL,
  appointment_id UNIQUEIDENTIFIER NULL,
  event_type NVARCHAR(60) NOT NULL,
  actor_role NVARCHAR(30) NOT NULL,
  actor_user_id UNIQUEIDENTIFIER NULL,
  target_type NVARCHAR(60) NOT NULL,
  target_id UNIQUEIDENTIFIER NULL,
  metadata_json NVARCHAR(MAX) NULL,
  occurred_at DATETIME2(3) NOT NULL CONSTRAINT DF_audit_events_occurred DEFAULT (SYSUTCDATETIME()),
  CONSTRAINT FK_audit_events_facility FOREIGN KEY (facility_id) REFERENCES core.facilities(facility_id)
);

GO
-- Append-only enforcement trigger
IF OBJECT_ID('audit.trg_audit_events_no_update_delete','TR') IS NULL
EXEC('
CREATE TRIGGER audit.trg_audit_events_no_update_delete
ON audit.audit_events
INSTEAD OF UPDATE, DELETE
AS
BEGIN
  RAISERROR(''audit_events is append-only. Updates/Deletes are not permitted.'', 16, 1);
END
');
GO
