/* =========================================================
   Views (reporting)
   ========================================================= */

GO

CREATE OR ALTER VIEW core.vw_appointments_reporting
AS
SELECT
  a.appointment_id,
  a.facility_id,
  f.name AS facility_name,
  a.resident_id,
  (r.last_name + ', ' + r.first_name) AS resident_name,
  a.vendor_id,
  v.legal_name AS vendor_name,
  a.service_id,
  s.service_name,
  a.start_time,
  a.end_time,
  DATEDIFF(MINUTE, a.start_time, a.end_time) AS duration_minutes,
  a.status,
  a.created_at,
  a.updated_at
FROM core.appointments a
JOIN core.facilities f ON f.facility_id = a.facility_id
JOIN core.residents r  ON r.resident_id = a.resident_id
JOIN core.vendors v    ON v.vendor_id = a.vendor_id
JOIN core.services s   ON s.service_id = a.service_id;
GO
