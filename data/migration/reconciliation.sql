/* =========================================================
   Migration Reconciliation Checks
   ========================================================= */

-- 1) Residents must have facility_id
SELECT COUNT(*) AS residents_missing_facility
FROM core.residents
WHERE facility_id IS NULL;

-- 2) Duplicate residents by facility + external key
SELECT facility_id, external_resident_key, COUNT(*) AS dup_count
FROM core.residents
WHERE external_resident_key IS NOT NULL
GROUP BY facility_id, external_resident_key
HAVING COUNT(*) > 1;

-- 3) Facility-vendor duplicates (should be prevented by unique index)
SELECT facility_id, vendor_id, COUNT(*) AS dup_count
FROM core.facility_vendors
GROUP BY facility_id, vendor_id
HAVING COUNT(*) > 1;

-- 4) Appointments must map to valid dimensions
SELECT COUNT(*) AS appts_missing_fk
FROM core.appointments a
LEFT JOIN core.facilities f ON f.facility_id = a.facility_id
LEFT JOIN core.residents r  ON r.resident_id = a.resident_id
LEFT JOIN core.vendors v    ON v.vendor_id = a.vendor_id
LEFT JOIN core.services s   ON s.service_id = a.service_id
WHERE f.facility_id IS NULL OR r.resident_id IS NULL OR v.vendor_id IS NULL OR s.service_id IS NULL;

-- 5) Row counts by facility (good for “before/after” reporting)
SELECT f.name, COUNT(*) AS resident_count
FROM core.residents r
JOIN core.facilities f ON f.facility_id = r.facility_id
GROUP BY f.name
ORDER BY resident_count DESC;
