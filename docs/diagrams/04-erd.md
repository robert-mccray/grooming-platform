erDiagram
  FACILITIES ||--o{ RESIDENTS : has
  FACILITIES ||--o{ STAFF_USERS : employs
  FACILITIES ||--o{ FACILITY_VENDORS : contracts
  VENDORS ||--o{ FACILITY_VENDORS : serves

  FACILITIES ||--o{ APPOINTMENTS : scopes
  RESIDENTS ||--o{ APPOINTMENTS : receives
  VENDORS ||--o{ APPOINTMENTS : performs
  SERVICES ||--o{ APPOINTMENTS : type

  APPOINTMENTS ||--o{ APPROVAL_EVENTS : changes
  APPOINTMENTS ||--o{ AUDIT_EVENTS : audited

  FACILITIES {
    uniqueidentifier facility_id PK
    nvarchar name
    nvarchar timezone
    nvarchar status
    datetime2 created_at
  }

  STAFF_USERS {
    uniqueidentifier user_id PK
    uniqueidentifier facility_id FK
    nvarchar display_name
    nvarchar email
    nvarchar role
    nvarchar status
    datetime2 created_at
  }

  VENDORS {
    uniqueidentifier vendor_id PK
    nvarchar legal_name
    nvarchar phone
    nvarchar email
    nvarchar license_number
    nvarchar status
    datetime2 created_at
  }

  FACILITY_VENDORS {
    uniqueidentifier facility_vendor_id PK
    uniqueidentifier facility_id FK
    uniqueidentifier vendor_id FK
    nvarchar onboarding_status
    datetime2 start_date
    datetime2 end_date
    datetime2 created_at
  }

  RESIDENTS {
    uniqueidentifier resident_id PK
    uniqueidentifier facility_id FK
    nvarchar external_resident_key
    nvarchar first_name
    nvarchar last_name
    date date_of_birth
    nvarchar room
    nvarchar status
    datetime2 created_at
  }

  SERVICES {
    uniqueidentifier service_id PK
    nvarchar service_name
    int default_duration_minutes
    bit requires_staff_presence
    bit is_active
    datetime2 created_at
  }

  APPOINTMENTS {
    uniqueidentifier appointment_id PK
    uniqueidentifier facility_id FK
    uniqueidentifier resident_id FK
    uniqueidentifier vendor_id FK
    uniqueidentifier service_id FK
    datetime2 start_time
    datetime2 end_time
    nvarchar status
    nvarchar requested_by_role
    uniqueidentifier requested_by_user_id
    datetime2 created_at
    datetime2 updated_at
  }

  APPROVAL_EVENTS {
    uniqueidentifier approval_event_id PK
    uniqueidentifier appointment_id FK
    uniqueidentifier facility_id FK
    nvarchar action
    nvarchar actor_role
    uniqueidentifier actor_user_id
    nvarchar reason
    datetime2 occurred_at
  }

  AUDIT_EVENTS {
    uniqueidentifier audit_event_id PK
    uniqueidentifier facility_id FK
    uniqueidentifier appointment_id FK
    nvarchar event_type
    nvarchar actor_role
    uniqueidentifier actor_user_id
    nvarchar target_type
    uniqueidentifier target_id
    nvarchar metadata_json
    datetime2 occurred_at
  }
