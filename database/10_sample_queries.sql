-- ============================================================
-- SKYPORT INTERNATIONAL AIRPORT DATABASE
-- 10_sample_queries.sql — Advanced Queries & Outer Joins
-- ============================================================

USE skyport_airport;

-- ============================================================
-- LEFT OUTER JOIN: All flights with their gate assignments
-- (including flights with NO gate assigned)
-- ============================================================

SELECT 
    '=== LEFT OUTER JOIN ===' AS query_type,
    'All flights including those without gate assignments' AS description;

SELECT 
    f.flight_id,
    f.flight_number,
    a.airline_name,
    f.origin_airport,
    f.destination_airport,
    f.scheduled_departure,
    f.status AS flight_status,
    g.gate_number,
    t.terminal_name,
    CASE 
        WHEN g.gate_number IS NULL THEN '** NO GATE ASSIGNED **'
        ELSE CONCAT(t.terminal_name, ' - Gate ', g.gate_number)
    END AS gate_info
FROM flights f
LEFT OUTER JOIN gate_assignments ga ON f.flight_id = ga.flight_id AND ga.status = 'ACTIVE'
LEFT OUTER JOIN gates g ON ga.gate_id = g.gate_id
LEFT OUTER JOIN terminals t ON g.terminal_id = t.terminal_id
JOIN airlines a ON f.airline_id = a.airline_id
ORDER BY f.scheduled_departure;

-- ============================================================
-- RIGHT OUTER JOIN: All gates with their flight assignments
-- (including gates with NO flight assigned)
-- ============================================================

SELECT 
    '=== RIGHT OUTER JOIN ===' AS query_type,
    'All gates including those with no flights assigned' AS description;

SELECT 
    g.gate_id,
    g.gate_number,
    t.terminal_name,
    g.gate_type,
    g.is_available,
    f.flight_number,
    f.destination_airport,
    f.scheduled_departure,
    f.status AS flight_status,
    CASE 
        WHEN f.flight_number IS NULL THEN '** GATE EMPTY **'
        ELSE CONCAT(f.flight_number, ' → ', f.destination_airport)
    END AS assignment_info
FROM gate_assignments ga
RIGHT OUTER JOIN gates g ON ga.gate_id = g.gate_id AND ga.status = 'ACTIVE'
JOIN terminals t ON g.terminal_id = t.terminal_id
LEFT JOIN flights f ON ga.flight_id = f.flight_id
ORDER BY t.terminal_name, g.gate_number;

-- ============================================================
-- FULL OUTER JOIN (emulated in MySQL using UNION)
-- All employees and all flight assignments
-- Shows employees without flights AND flights without specific crew roles
-- ============================================================

SELECT 
    '=== FULL OUTER JOIN (Emulated) ===' AS query_type,
    'All employees and all flight assignments - including unmatched on both sides' AS description;

-- MySQL doesn't support FULL OUTER JOIN natively, so we emulate with UNION
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.employee_type,
    fca.role AS crew_role,
    f.flight_number,
    f.scheduled_departure,
    CASE 
        WHEN f.flight_number IS NULL THEN '** NO FLIGHT ASSIGNED **'
        ELSE 'Assigned'
    END AS assignment_status
FROM employees e
LEFT OUTER JOIN flight_crew_assignments fca ON e.employee_id = fca.employee_id
LEFT OUTER JOIN flights f ON fca.flight_id = f.flight_id
WHERE e.employee_type IN ('PILOT', 'CABIN_CREW')

UNION

SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    e.employee_type,
    fca.role AS crew_role,
    f.flight_number,
    f.scheduled_departure,
    CASE 
        WHEN e.employee_id IS NULL THEN '** NO CREW ASSIGNED **'
        ELSE 'Assigned'
    END AS assignment_status
FROM flight_crew_assignments fca
RIGHT OUTER JOIN employees e ON fca.employee_id = e.employee_id
RIGHT OUTER JOIN flights f ON fca.flight_id = f.flight_id
WHERE e.employee_id IS NULL

ORDER BY employee_name, flight_number;

-- ============================================================
-- ADVANCED QUERY 1: Subquery — Passengers who spent more than average
-- ============================================================

SELECT 
    '=== SUBQUERY: Above-Average Spenders ===' AS query_type;

SELECT 
    p.passenger_id,
    CONCAT(p.first_name, ' ', p.last_name) AS passenger_name,
    SUM(b.price) AS total_spent,
    (SELECT ROUND(AVG(price), 2) FROM bookings WHERE payment_status = 'PAID') AS avg_booking_price,
    COUNT(b.booking_id) AS total_bookings
FROM passengers p
JOIN bookings b ON p.passenger_id = b.passenger_id
WHERE b.payment_status = 'PAID'
GROUP BY p.passenger_id, p.first_name, p.last_name
HAVING total_spent > (SELECT AVG(price) * 2 FROM bookings WHERE payment_status = 'PAID')
ORDER BY total_spent DESC;

-- ============================================================
-- ADVANCED QUERY 2: Correlated Subquery — Airlines with above-avg occupancy
-- ============================================================

SELECT 
    '=== CORRELATED SUBQUERY: Top Performing Airlines ===' AS query_type;

SELECT 
    a.airline_name,
    a.airline_code,
    COUNT(f.flight_id) AS total_flights,
    ROUND(AVG((f.total_seats - f.available_seats) / f.total_seats * 100), 1) AS avg_occupancy_pct
FROM airlines a
JOIN flights f ON a.airline_id = f.airline_id
WHERE f.status != 'CANCELLED'
GROUP BY a.airline_id, a.airline_name, a.airline_code
HAVING avg_occupancy_pct > (
    SELECT AVG((f2.total_seats - f2.available_seats) / f2.total_seats * 100)
    FROM flights f2
    WHERE f2.status != 'CANCELLED'
)
ORDER BY avg_occupancy_pct DESC;

-- ============================================================
-- ADVANCED QUERY 3: Window Functions — Ranking passengers by spending
-- ============================================================

SELECT 
    '=== WINDOW FUNCTION: Passenger Spending Rank ===' AS query_type;

SELECT 
    CONCAT(p.first_name, ' ', p.last_name) AS passenger_name,
    b.booking_class,
    b.price,
    f.flight_number,
    al.airline_name,
    RANK() OVER (ORDER BY b.price DESC) AS spending_rank,
    DENSE_RANK() OVER (PARTITION BY al.airline_id ORDER BY b.price DESC) AS airline_rank,
    SUM(b.price) OVER (PARTITION BY al.airline_id) AS airline_total_revenue,
    ROUND(b.price / SUM(b.price) OVER (PARTITION BY al.airline_id) * 100, 1) AS pct_of_airline_revenue
FROM bookings b
JOIN passengers p ON b.passenger_id = p.passenger_id
JOIN flights f ON b.flight_id = f.flight_id
JOIN airlines al ON f.airline_id = al.airline_id
WHERE b.booking_status != 'CANCELLED'
ORDER BY spending_rank;

-- ============================================================
-- ADVANCED QUERY 4: Common Table Expression (CTE) — Flight delay analysis
-- ============================================================

SELECT 
    '=== CTE: Flight Delay Analysis ===' AS query_type;

WITH delay_stats AS (
    SELECT 
        a.airline_id,
        a.airline_name,
        COUNT(*) AS total_flights,
        SUM(CASE WHEN f.delay_minutes > 0 THEN 1 ELSE 0 END) AS delayed_count,
        AVG(CASE WHEN f.delay_minutes > 0 THEN f.delay_minutes END) AS avg_delay,
        MAX(f.delay_minutes) AS max_delay
    FROM flights f
    JOIN airlines a ON f.airline_id = a.airline_id
    GROUP BY a.airline_id, a.airline_name
),
airline_ratings AS (
    SELECT 
        *,
        ROUND((1 - delayed_count / total_flights) * 100, 1) AS on_time_pct,
        CASE 
            WHEN (delayed_count / total_flights) < 0.1 THEN 'EXCELLENT'
            WHEN (delayed_count / total_flights) < 0.25 THEN 'GOOD'
            WHEN (delayed_count / total_flights) < 0.5 THEN 'FAIR'
            ELSE 'POOR'
        END AS reliability_rating
    FROM delay_stats
)
SELECT * FROM airline_ratings ORDER BY on_time_pct DESC;

-- ============================================================
-- ADVANCED QUERY 5: EXISTS — Passengers with both bookings and shop purchases
-- ============================================================

SELECT 
    '=== EXISTS: Passengers who booked AND shopped ===' AS query_type;

SELECT 
    p.passenger_id,
    CONCAT(p.first_name, ' ', p.last_name) AS passenger_name,
    p.nationality
FROM passengers p
WHERE EXISTS (
    SELECT 1 FROM bookings b 
    WHERE b.passenger_id = p.passenger_id 
    AND b.booking_status != 'CANCELLED'
)
AND EXISTS (
    SELECT 1 FROM shop_transactions st
    WHERE st.passenger_id = p.passenger_id
)
ORDER BY p.last_name;

-- ============================================================
-- ADVANCED QUERY 6: CASE + GROUP BY — Revenue by booking class & route
-- ============================================================

SELECT 
    '=== Revenue Analysis by Route and Class ===' AS query_type;

SELECT 
    f.origin_airport,
    f.destination_airport,
    COUNT(b.booking_id) AS total_bookings,
    SUM(CASE WHEN b.booking_class = 'ECONOMY' THEN b.price ELSE 0 END) AS economy_revenue,
    SUM(CASE WHEN b.booking_class = 'PREMIUM_ECONOMY' THEN b.price ELSE 0 END) AS premium_revenue,
    SUM(CASE WHEN b.booking_class = 'BUSINESS' THEN b.price ELSE 0 END) AS business_revenue,
    SUM(CASE WHEN b.booking_class = 'FIRST' THEN b.price ELSE 0 END) AS first_revenue,
    SUM(b.price) AS total_revenue,
    ROUND(AVG(b.price), 2) AS avg_ticket_price
FROM flights f
JOIN bookings b ON f.flight_id = b.flight_id
WHERE b.booking_status != 'CANCELLED'
GROUP BY f.origin_airport, f.destination_airport
ORDER BY total_revenue DESC;

-- ============================================================
-- ADVANCED QUERY 7: Self-Join — Connecting flights for passengers
-- ============================================================

SELECT 
    '=== SELF-JOIN: Potential Connecting Flights ===' AS query_type;

SELECT 
    f1.flight_number AS first_flight,
    f1.origin_airport AS depart_from,
    f1.destination_airport AS connect_at,
    f1.scheduled_arrival AS arrive_connection,
    f2.flight_number AS connecting_flight,
    f2.destination_airport AS final_destination,
    f2.scheduled_departure AS depart_connection,
    TIMESTAMPDIFF(MINUTE, f1.scheduled_arrival, f2.scheduled_departure) AS layover_minutes
FROM flights f1
JOIN flights f2 ON f1.destination_airport = f2.origin_airport
    AND f2.scheduled_departure > f1.scheduled_arrival
    AND TIMESTAMPDIFF(MINUTE, f1.scheduled_arrival, f2.scheduled_departure) BETWEEN 60 AND 360
WHERE f1.status != 'CANCELLED' AND f2.status != 'CANCELLED'
    AND f1.origin_airport != f2.destination_airport
ORDER BY f1.flight_number, layover_minutes;

-- ============================================================
-- ADVANCED QUERY 8: Using functions in queries
-- ============================================================

SELECT 
    '=== Using Custom Functions ===' AS query_type;

SELECT 
    f.flight_number,
    f.origin_airport,
    f.destination_airport,
    fn_calculate_flight_duration(f.flight_id) AS duration_minutes,
    CONCAT(FLOOR(fn_calculate_flight_duration(f.flight_id) / 60), 'h ', 
           MOD(fn_calculate_flight_duration(f.flight_id), 60), 'm') AS duration_formatted,
    fn_flight_occupancy(f.flight_id) AS occupancy_pct,
    CASE 
        WHEN fn_flight_occupancy(f.flight_id) >= 90 THEN 'NEARLY FULL'
        WHEN fn_flight_occupancy(f.flight_id) >= 70 THEN 'HIGH DEMAND'
        WHEN fn_flight_occupancy(f.flight_id) >= 50 THEN 'MODERATE'
        ELSE 'LOW'
    END AS demand_level
FROM flights f
WHERE f.status != 'CANCELLED'
ORDER BY occupancy_pct DESC;
