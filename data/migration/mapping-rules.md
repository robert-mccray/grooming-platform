# Migration Mapping Rules — Legacy Roster Export → Azure SQL (core.*)

## Source file
`legacy_roster_export.csv`

## Target tables
- core.facilities
- core.residents
- core.vendors
- core.facility_vendors
- core.services
- (Optional) core.appointments (if LastGroomedDate used to create historical appointments)

---

## Facilities
**Source fields**
- FacilityCode, FacilityName

**Target**
- core.facilities
  - facility_id: generated (GUID) via lookup table or deterministic mapping
  - name: FacilityName
  - timezone: default 'America/Chicago'
  - status: 'active'

**Rule**
- FacilityCode is treated as a *business key*.
- Maintain a mapping table in ADF (or a seed table) from FacilityCode → facility_id.

---

## Residents
**Source fields**
- ResidentExternalId, ResidentFirstName, ResidentLastName, DOB, Room, FacilityCode

**Target**
- core.residents
  - resident_id: generated GUID
  - facility_id: lookup via FacilityCode mapping
  - external_resident_key: ResidentExternalId
  - first_name, last_name: source
  - date_of_birth: DOB
  - room: Room
  - status: 'active'

**Rules**
- Deduplicate by (FacilityCode, ResidentExternalId).
- If duplicate rows exist, keep the most recent row and log duplicates to a reject file.

---

## Vendors
**Source fields**
- VendorName

**Target**
- core.vendors
  - vendor_id: generated GUID
  - legal_name: VendorName
  - status: 'active'

**Rules**
- Deduplicate by VendorName (case-insensitive).
- If vendor exists, do not create again.

---

## Facility-Vendor relationship
**Source fields**
- FacilityCode, VendorName

**Target**
- core.facility_vendors
  - facility_vendor_id: generated GUID
  - facility_id: lookup via FacilityCode
  - vendor_id: lookup by VendorName
  - onboarding_status: 'approved'
  - start_date: load date

**Rules**
- Deduplicate by (facility_id, vendor_id).
- Set onboarding_status='approved' for initial migration.

---

## Services
**Source fields**
- ServiceName, DefaultDurationMin, RequiresStaffPresence, ActiveFlag

**Target**
- core.services
  - service_id: generated GUID
  - service_name: ServiceName
  - default_duration_minutes: DefaultDurationMin
  - requires_staff_presence: RequiresStaffPresence (true/false → bit)
  - is_active: ActiveFlag (1/0 → bit)

**Rules**
- Deduplicate by ServiceName.
- If conflicting durations occur for same ServiceName, keep the max duration and log variance.

---

## Optional: Create historical "completed" appointment from LastGroomedDate
**Source fields**
- LastGroomedDate, FacilityCode, ResidentExternalId, VendorName, ServiceName

**Target**
- core.appointments
  - appointment_id: generated GUID
  - facility_id: lookup
  - resident_id: lookup (Facility + ExternalId)
  - vendor_id: lookup
  - service_id: lookup
  - start_time: LastGroomedDate at 10:00 local (or noon) converted to UTC
  - end_time: start_time + DefaultDurationMin
  - status: 'completed'
  - requested_by_role: 'system'
  - created_at/updated_at: migration timestamp

**Rules**
- Only generate historical appointments if LastGroomedDate is populated.
- If date parsing fails, route to rejects.
