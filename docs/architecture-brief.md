# Living Care Grooming Services Platform (Azure) — Architecture Brief

## 1) Overview
This project is a role-based scheduling, tracking, and audit-aware workflow platform designed for grooming services delivered inside living care facilities (barbers, salon, nails). The goal is to model regulated-adjacent operational workflows with strong data governance, analytics readiness, and cost-aware cloud design.

**Primary outcomes**
- Standardize booking + approval workflows (reduce coordination overhead)
- Create an audit trail for schedule changes, access, and exceptions
- Enable facility operations and vendor performance reporting through a lakehouse-lite analytics pattern

## 2) Actors and Core Workflows
**Roles**
- Facility Admin: manages vendors, staffing visibility, approvals, reporting
- Facility Staff: schedules residents, supports day-of operations, records completion
- Vendor: requests slots, views assigned schedule, marks services complete
- Viewer/Owner: read-only reporting access

**Workflow state machine**
`requested → approved | denied → completed | cancelled`
All overrides require a reason and are recorded as audit events.

## 3) Constraints and Design Principles
- Minimal cost for short-lived development and handoff, with an enterprise-grade upgrade path
- Least privilege access and clear trust boundaries (vendors ≠ staff)
- Data governance is treated as a product feature, not an afterthought
- Analytics without always-on warehousing (serverless query pattern)

## 4) Architecture Summary (Minimal Azure Stack)
**Compute**
- Azure Container Apps: API + background worker (scale-to-zero)

**Operational data**
- Azure SQL Database: OLTP schema + audit tables + backups (PITR)

**Integration and pipelines**
- Azure Data Factory: ingest legacy rosters, export operational/audit datasets, transform to analytics-ready tables

**Data lake + analytics**
- ADLS Gen2: bronze/silver/gold zones (partitioned parquet)
- Synapse Serverless: views over gold for lightweight BI querying

**BI**
- Power BI: operational dashboards + compliance visibility + role-based access

**Observability**
- App Insights + Log Analytics: correlated traces, KQL queries for audits and reliability metrics

## 5) Data Governance and Secure Sharing
**Governance controls**
- Data classification: PII vs non-PII fields, with documented handling rules
- RBAC: Entra app roles (facility_admin, staff, vendor, viewer)
- Managed identities for service-to-service access (ACA/ADF to SQL/ADLS)
- Audit events: immutable records for critical actions and overrides
- Retention: separate policies for operational records, audit logs, and analytics aggregates

**Secure sharing**
- Operational access: role-based API authorization
- Reporting access: Power BI workspace roles + dataset permissions + row-level security where applicable
- Exports: controlled file outputs to the lake (no ad-hoc downloads from production DB)

## 6) Data Modeling
**OLTP (Azure SQL) key entities**
- facilities, residents, vendors, services
- appointments (with status transitions)
- approval_events (who approved/denied, when, why)
- audit_events (append-only audit trail)

**Analytics (Gold zone)**
Star schema pattern for reporting:
- FactAppointments (volume, duration, status, completion)
- FactCancellations (reason, lead time)
- DimFacility, DimVendor, DimService, DimDate

## 7) Data Integration & ETL (ADF + Lakehouse-lite)
**Ingest**
- Legacy roster (CSV/Excel) → validated → loaded to Azure SQL
- Optional vendor schedule feed → staged → loaded to SQL

**Export**
- Operational bookings + audit events → ADLS Bronze (raw extracts)
- Bronze → Silver (cleaned, validated, deduped)
- Silver → Gold (reporting-ready parquet + partitioning)

**Quality & reconciliation**
- Row counts by facility/date
- Referential integrity checks (e.g., appointment must map to resident/vendor)
- Duplicate detection and resolution rules

## 8) DBA: Performance, Backups, Security
**DBA controls**
- PITR backups (default Azure SQL capability)
- Index strategy for hot paths:
  - appointments by facility_id + start_time
  - audit_events by timestamp + facility_id
- Query tuning and view design for common reporting needs
- Optional: row-level security for multi-facility isolation

## 9) Performance Tuning & Cost Optimization
**Cost-first decisions**
- Container Apps scale-to-zero for dev environments
- Synapse Serverless (pay-per-query) instead of always-on warehouse
- Parquet partitioning by date and facility for lower scan costs
- Power BI Import for small dimensions; selective DirectQuery/Serverless views for larger facts

**Upgrade path (10× volume)**
- Event streaming (Service Bus/Event Hubs) for near-real-time analytics
- Dedicated warehouse (Fabric/Synapse dedicated or Snowflake) when query concurrency rises
- Separate audit store and immutable log pipeline if compliance demands increase

## 10) What We Intentionally Did Not Build
- Native mobile apps (web-first workflow validation)
- Marketplace / billing complexity (focus on facility operations first)
- AKS (unnecessary operational overhead for this phase)
- Full HIPAA positioning (regulated-adjacent controls demonstrated without overstating scope)

## 11) Skills & Pillars Demonstrated (SOW Mapping)
- Data Governance: RBAC, audit, retention, secure sharing
- Data Modeling: OLTP ERD + analytics star schema
- Azure Data Services: ADF, Azure SQL, Synapse serverless, ADLS
- BI: Power BI dashboards, operational metrics and compliance visibility
- DBA: indexing, backups/PITR, performance tuning
- Data Migration: legacy roster ingestion + reconciliation
- Data Architecture: scalable lakehouse-lite pattern with upgrade path
- ETL Pipelines: structured and semi-structured flows, partitioned parquet
- Cost Optimization: serverless and scale-to-zero patterns