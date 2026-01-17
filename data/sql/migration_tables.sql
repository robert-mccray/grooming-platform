SET NOCOUNT ON;

IF OBJECT_ID('audit.migration_rejects','U') IS NULL
CREATE TABLE audit.migration_rejects (
  reject_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_migration_rejects PRIMARY KEY,
  pipeline_run_id NVARCHAR(80) NOT NULL,
  source_file_name NVARCHAR(260) NULL,
  entity_type NVARCHAR(60) NOT NULL,          -- Resident/Vendor/Service/FacilityVendor/etc.
  facility_code NVARCHAR(60) NULL,
  reject_reason_code NVARCHAR(80) NOT NULL,    -- e.g., DOB_INVALID
  reject_reason_detail NVARCHAR(400) NULL,
  raw_row_json NVARCHAR(MAX) NULL,             -- store original record for audit/debug
  ingested_at_utc DATETIME2(3) NOT NULL CONSTRAINT DF_migration_rejects_ingested DEFAULT (SYSUTCDATETIME())
);

IF OBJECT_ID('audit.migration_run_metrics','U') IS NULL
CREATE TABLE audit.migration_run_metrics (
  metrics_id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_migration_run_metrics PRIMARY KEY,
  pipeline_run_id NVARCHAR(80) NOT NULL,
  source_file_name NVARCHAR(260) NULL,
  entity_type NVARCHAR(60) NOT NULL,           -- Facilities/Residents/Vendors/Services/FacilityVendors
  rows_read INT NOT NULL,
  rows_loaded INT NOT NULL,
  rows_rejected INT NOT NULL,
  started_at_utc DATETIME2(3) NOT NULL,
  finished_at_utc DATETIME2(3) NOT NULL,
  created_at_utc DATETIME2(3) NOT NULL CONSTRAINT DF_migration_run_metrics_created DEFAULT (SYSUTCDATETIME())
);

-- Helpful index for viewing run summaries
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_migration_run_metrics_run')
CREATE INDEX IX_migration_run_metrics_run
ON audit.migration_run_metrics(pipeline_run_id, entity_type, finished_at_utc DESC);
