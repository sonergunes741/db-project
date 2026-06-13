-- ============================================================
-- SKYPORT INTERNATIONAL AIRPORT DATABASE
-- 04_views.sql — All Views (11)
-- ============================================================

USE skyport_airport;

-- ============================================================
-- VIEW 1: Flight Dashboard (live departure/arrival board)
-- ============================================================
DROP VIEW IF EXISTS vw_flight_dashboard;
CREATE VIEW vw_flight_dashboard AS
SELECT 
    f.flight_id,
    f.flight_number,
    a.airline_name,
    a.airline_code,
    f.origin_airport,
    f.destination_airport,
    f.scheduled_departure,
    f.scheduled_arrival,
    f.actual_departure,
    f.actual_arrival,
    f.status,
    f.delay_minutes,
    f.delay_reason,
    f.flight_type,
    at.manufacturer AS aircraft_manufacturer,
    at.model AS aircraft_model,
    ac.registration_no,
    g.gate_number,
    t.terminal_name,
    f.total_seats,
    f.available_seats,
    (f.total_seats - f.available_seats) AS booked_seats,
    ROUND(((f.total_seats - f.available_seats) / f.total_seats) * 100, 1) AS occupancy_pct
FROM flights f
JOIN airlines a ON f.airline_id = a.airline_id
LEFT JOIN aircraft ac ON f.aircraft_id = ac.aircraft_id
LEFT JOIN aircraft_types at ON ac.type_id = at.type_id
LEFT JOIN gate_assignments ga ON f.flight_id = ga.flight_id AND ga.status = 'ACTIVE'
LEFT JOIN gates g ON ga.gate_id = g.gate_id
LEFT JOIN terminals t ON g.terminal_id = t.terminal_id;

-- ============================================================
-- VIEW 2: Passenger Itinerary
-- ============================================================
DROP VIEW IF EXISTS vw_passenger_itinerary;
CREATE VIEW vw_passenger_itinerary AS
SELECT 
    p.passenger_id,
    CONCAT(p.first_name, ' ', p.last_name) AS passenger_name,
    p.passport_number,
    p.nationality,
    b.booking_ref,
    b.booking_id,
    b.booking_class,
    b.seat_number,
    b.price,
    b.booking_status,
    b.payment_status,
    f.flight_number,
    f.origin_airport,
    f.destination_airport,
    f.scheduled_departure,
    f.scheduled_arrival,
    f.status AS flight_status,
    al.airline_name,
    bp.barcode AS boarding_barcode,
    bp.boarding_group,
    bp.is_boarded,
    g.gate_number,
    t.terminal_name
FROM passengers p
JOIN bookings b ON p.passenger_id = b.passenger_id
JOIN flights f ON b.flight_id = f.flight_id
JOIN airlines al ON f.airline_id = al.airline_id
LEFT JOIN boarding_passes bp ON b.booking_id = bp.booking_id
LEFT JOIN gates g ON bp.gate_id = g.gate_id
LEFT JOIN terminals t ON g.terminal_id = t.terminal_id;

-- ============================================================
-- VIEW 3: Airline Statistics
-- ============================================================
DROP VIEW IF EXISTS vw_airline_statistics;
CREATE VIEW vw_airline_statistics AS
SELECT 
    a.airline_id,
    a.airline_code,
    a.airline_name,
    a.alliance,
    COUNT(DISTINCT f.flight_id) AS total_flights,
    COUNT(DISTINCT ac.aircraft_id) AS fleet_size,
    SUM(CASE WHEN f.status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_flights,
    SUM(CASE WHEN f.status = 'DELAYED' THEN 1 ELSE 0 END) AS delayed_flights,
    ROUND(AVG(CASE WHEN f.delay_minutes > 0 THEN f.delay_minutes END), 1) AS avg_delay_min,
    COUNT(DISTINCT b.booking_id) AS total_bookings,
    COALESCE(SUM(CASE WHEN b.payment_status = 'PAID' THEN b.price ELSE 0 END), 0) AS total_revenue,
    ROUND(AVG(CASE WHEN f.total_seats > 0 
        THEN ((f.total_seats - f.available_seats) / f.total_seats) * 100 END), 1) AS avg_occupancy_pct
FROM airlines a
LEFT JOIN flights f ON a.airline_id = f.airline_id
LEFT JOIN aircraft ac ON a.airline_id = ac.airline_id
LEFT JOIN bookings b ON f.flight_id = b.flight_id AND b.booking_status != 'CANCELLED'
GROUP BY a.airline_id, a.airline_code, a.airline_name, a.alliance;

-- ============================================================
-- VIEW 4: Gate Availability
-- ============================================================
DROP VIEW IF EXISTS vw_gate_availability;
CREATE VIEW vw_gate_availability AS
SELECT 
    g.gate_id,
    g.gate_number,
    t.terminal_name,
    g.gate_type,
    g.is_available,
    ga.flight_id,
    f.flight_number,
    f.destination_airport,
    ga.start_time,
    ga.end_time,
    ga.status AS assignment_status
FROM gates g
JOIN terminals t ON g.terminal_id = t.terminal_id
LEFT JOIN gate_assignments ga ON g.gate_id = ga.gate_id AND ga.status = 'ACTIVE'
LEFT JOIN flights f ON ga.flight_id = f.flight_id;

-- ============================================================
-- VIEW 5: Baggage Tracking
-- ============================================================
DROP VIEW IF EXISTS vw_baggage_tracking;
CREATE VIEW vw_baggage_tracking AS
SELECT 
    bg.baggage_id,
    bg.tag_number,
    bg.weight_kg,
    bg.baggage_type,
    bg.status AS baggage_status,
    CONCAT(p.first_name, ' ', p.last_name) AS passenger_name,
    b.booking_ref,
    f.flight_number,
    f.origin_airport,
    f.destination_airport,
    f.status AS flight_status,
    bc.claim_id,
    bc.claim_type,
    bc.claim_status,
    bc.compensation
FROM baggage bg
JOIN bookings b ON bg.booking_id = b.booking_id
JOIN passengers p ON b.passenger_id = p.passenger_id
JOIN flights f ON b.flight_id = f.flight_id
LEFT JOIN baggage_claims bc ON bg.baggage_id = bc.baggage_id;

-- ============================================================
-- VIEW 6: Crew Schedule
-- ============================================================
DROP VIEW IF EXISTS vw_crew_schedule;
CREATE VIEW vw_crew_schedule AS
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS crew_name,
    e.employee_type,
    fca.role,
    f.flight_number,
    f.origin_airport,
    f.destination_airport,
    f.scheduled_departure,
    f.scheduled_arrival,
    f.status AS flight_status,
    al.airline_name,
    CASE 
        WHEN e.employee_type = 'PILOT' THEN pl.license_type
        WHEN e.employee_type = 'CABIN_CREW' THEN cc.position
        ELSE NULL
    END AS specialization
FROM flight_crew_assignments fca
JOIN employees e ON fca.employee_id = e.employee_id
JOIN flights f ON fca.flight_id = f.flight_id
JOIN airlines al ON f.airline_id = al.airline_id
LEFT JOIN pilots pl ON e.employee_id = pl.pilot_id
LEFT JOIN cabin_crew cc ON e.employee_id = cc.crew_id;

-- ============================================================
-- VIEW 7: Maintenance Status
-- ============================================================
DROP VIEW IF EXISTS vw_maintenance_status;
CREATE VIEW vw_maintenance_status AS
SELECT 
    mr.record_id,
    ac.registration_no,
    at.manufacturer,
    at.model,
    al.airline_name,
    mr.maintenance_type,
    mr.description,
    mr.start_date,
    mr.end_date,
    mr.status,
    mr.cost,
    mr.parts_replaced,
    CONCAT(e.first_name, ' ', e.last_name) AS technician_name,
    ac.status AS aircraft_status,
    ac.total_flight_hours,
    ac.next_maintenance
FROM maintenance_records mr
JOIN aircraft ac ON mr.aircraft_id = ac.aircraft_id
JOIN aircraft_types at ON ac.type_id = at.type_id
JOIN airlines al ON ac.airline_id = al.airline_id
LEFT JOIN employees e ON mr.performed_by = e.employee_id;

-- ============================================================
-- VIEW 8: Revenue Report
-- ============================================================
DROP VIEW IF EXISTS vw_revenue_report;
CREATE VIEW vw_revenue_report AS
SELECT 
    al.airline_id,
    al.airline_name,
    al.airline_code,
    f.flight_number,
    f.origin_airport,
    f.destination_airport,
    DATE(f.scheduled_departure) AS flight_date,
    COUNT(b.booking_id) AS bookings_count,
    SUM(CASE WHEN b.booking_class = 'ECONOMY' THEN 1 ELSE 0 END) AS economy_bookings,
    SUM(CASE WHEN b.booking_class = 'BUSINESS' THEN 1 ELSE 0 END) AS business_bookings,
    SUM(CASE WHEN b.booking_class = 'FIRST' THEN 1 ELSE 0 END) AS first_bookings,
    SUM(CASE WHEN b.payment_status = 'PAID' THEN b.price ELSE 0 END) AS paid_revenue,
    SUM(CASE WHEN b.payment_status = 'REFUNDED' THEN b.price ELSE 0 END) AS refunded_amount
FROM airlines al
JOIN flights f ON al.airline_id = f.airline_id
LEFT JOIN bookings b ON f.flight_id = b.flight_id
GROUP BY al.airline_id, al.airline_name, al.airline_code, 
         f.flight_number, f.origin_airport, f.destination_airport, DATE(f.scheduled_departure);

-- ============================================================
-- VIEW 9: Delayed Flights
-- ============================================================
DROP VIEW IF EXISTS vw_delayed_flights;
CREATE VIEW vw_delayed_flights AS
SELECT 
    f.flight_id,
    f.flight_number,
    al.airline_name,
    f.origin_airport,
    f.destination_airport,
    f.scheduled_departure,
    f.actual_departure,
    f.status,
    f.delay_minutes,
    f.delay_reason,
    COUNT(b.booking_id) AS affected_passengers,
    g.gate_number,
    t.terminal_name
FROM flights f
JOIN airlines al ON f.airline_id = al.airline_id
LEFT JOIN bookings b ON f.flight_id = b.flight_id AND b.booking_status != 'CANCELLED'
LEFT JOIN gate_assignments ga ON f.flight_id = ga.flight_id AND ga.status = 'ACTIVE'
LEFT JOIN gates g ON ga.gate_id = g.gate_id
LEFT JOIN terminals t ON g.terminal_id = t.terminal_id
WHERE f.status IN ('DELAYED', 'CANCELLED') OR f.delay_minutes > 0
GROUP BY f.flight_id, f.flight_number, al.airline_name, f.origin_airport, f.destination_airport,
         f.scheduled_departure, f.actual_departure, f.status, f.delay_minutes, f.delay_reason,
         g.gate_number, t.terminal_name;

-- ============================================================
-- VIEW 10: Employee Directory (unified view across all types)
-- ============================================================
DROP VIEW IF EXISTS vw_employee_directory;
CREATE VIEW vw_employee_directory AS
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS full_name,
    e.email,
    e.phone,
    e.employee_type,
    e.hire_date,
    e.salary,
    e.is_active,
    al.airline_name,
    CASE e.employee_type
        WHEN 'PILOT' THEN CONCAT('License: ', p.license_type, ' | Hours: ', p.total_flight_hours, ' | Rating: ', COALESCE(p.rating, 'N/A'))
        WHEN 'CABIN_CREW' THEN CONCAT('Position: ', cc.position, ' | Languages: ', COALESCE(cc.languages_spoken, 'N/A'))
        WHEN 'GROUND_STAFF' THEN CONCAT('Dept: ', gs.department, ' | Shift: ', gs.shift_pattern)
        WHEN 'SECURITY' THEN CONCAT('Clearance: ', sp.clearance_level, ' | Zone: ', COALESCE(sp.assigned_zone, 'N/A'))
    END AS specialization_details,
    CASE e.employee_type
        WHEN 'PILOT' THEN p.license_number
        WHEN 'SECURITY' THEN sp.badge_number
        ELSE NULL
    END AS badge_or_license
FROM employees e
LEFT JOIN airlines al ON e.airline_id = al.airline_id
LEFT JOIN pilots p ON e.employee_id = p.pilot_id
LEFT JOIN cabin_crew cc ON e.employee_id = cc.crew_id
LEFT JOIN ground_staff gs ON e.employee_id = gs.staff_id
LEFT JOIN security_personnel sp ON e.employee_id = sp.security_id;

-- ============================================================
-- VIEW 11: Parking Availability
-- ============================================================
DROP VIEW IF EXISTS vw_parking_availability;
CREATE VIEW vw_parking_availability AS
SELECT 
    pl.lot_id,
    pl.lot_name,
    pl.lot_type,
    pl.total_spots,
    pl.available_spots,
    (pl.total_spots - pl.available_spots) AS occupied_spots,
    ROUND(((pl.total_spots - pl.available_spots) / pl.total_spots) * 100, 1) AS occupancy_pct,
    pl.hourly_rate,
    pl.daily_max,
    pl.is_covered,
    t.terminal_name,
    COUNT(pr.reservation_id) AS active_reservations
FROM parking_lots pl
LEFT JOIN terminals t ON pl.terminal_id = t.terminal_id
LEFT JOIN parking_reservations pr ON pl.lot_id = pr.lot_id AND pr.status = 'ACTIVE'
GROUP BY pl.lot_id, pl.lot_name, pl.lot_type, pl.total_spots, pl.available_spots,
         pl.hourly_rate, pl.daily_max, pl.is_covered, t.terminal_name;
