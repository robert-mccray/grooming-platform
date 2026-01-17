erDiagram
  DIM_DATE ||--o{ FACT_APPOINTMENTS : by_date
  DIM_FACILITY ||--o{ FACT_APPOINTMENTS : by_facility
  DIM_VENDOR ||--o{ FACT_APPOINTMENTS : by_vendor
  DIM_SERVICE ||--o{ FACT_APPOINTMENTS : by_service

  DIM_DATE ||--o{ FACT_CANCELLATIONS : by_date
  DIM_FACILITY ||--o{ FACT_CANCELLATIONS : by_facility
  DIM_VENDOR ||--o{ FACT_CANCELLATIONS : by_vendor
  DIM_SERVICE ||--o{ FACT_CANCELLATIONS : by_service

  DIM_DATE {
    int date_key PK
    date calendar_date
    int year
    int month
    int day
    int week_of_year
  }

  DIM_FACILITY {
    uniqueidentifier facility_id PK
    nvarchar facility_name
    nvarchar timezone
    nvarchar status
  }

  DIM_VENDOR {
    uniqueidentifier vendor_id PK
    nvarchar vendor_name
    nvarchar status
  }

  DIM_SERVICE {
    uniqueidentifier service_id PK
    nvarchar service_name
    int default_duration_minutes
  }

  FACT_APPOINTMENTS {
    bigint fact_id PK
    int date_key FK
    uniqueidentifier facility_id FK
    uniqueidentifier vendor_id FK
    uniqueidentifier service_id FK
    int appointment_count
    int completed_count
    int denied_count
    int cancelled_count
    int total_minutes
  }

  FACT_CANCELLATIONS {
    bigint fact_id PK
    int date_key FK
    uniqueidentifier facility_id FK
    uniqueidentifier vendor_id FK
    uniqueidentifier service_id FK
    nvarchar cancel_reason
    int cancel_count
    int avg_lead_minutes
  }
