-- ============================================================
-- SKYPORT INTERNATIONAL AIRPORT DATABASE
-- 09_normalization_examples.sql — Normalization Demonstrations
-- ============================================================

USE skyport_airport;

-- ============================================================
-- EXAMPLE 1: Denormalized Flight Details → 3NF Decomposition
-- ============================================================

-- BEFORE: A single denormalized relation (NOT in 3NF)
-- flight_details_denorm(flight_id, flight_number, airline_code, airline_name, 
--   airline_country, aircraft_reg, aircraft_type_code, manufacturer, model, 
--   max_passengers, origin, destination, departure, arrival, price)
--
-- FUNCTIONAL DEPENDENCIES:
--   flight_id → flight_number, airline_code, aircraft_reg, origin, destination, departure, arrival, price
--   airline_code → airline_name, airline_country         ← TRANSITIVE DEPENDENCY (violates 3NF)
--   aircraft_reg → aircraft_type_code                    ← TRANSITIVE DEPENDENCY (violates 3NF)
--   aircraft_type_code → manufacturer, model, max_passengers  ← TRANSITIVE DEPENDENCY (violates 3NF)
--
-- PROBLEMS:
--   1. UPDATE ANOMALY: Changing airline name requires updating ALL rows for that airline
--   2. INSERT ANOMALY: Cannot store a new airline without creating a flight
--   3. DELETE ANOMALY: Deleting last flight for an airline loses airline data

DROP TABLE IF EXISTS flight_details_denorm;
CREATE TABLE flight_details_denorm (
    flight_id           INT PRIMARY KEY,
    flight_number       VARCHAR(10),
    airline_code        CHAR(2),
    airline_name        VARCHAR(100),      -- Depends on airline_code, NOT flight_id
    airline_country     VARCHAR(60),       -- Depends on airline_code, NOT flight_id
    aircraft_reg        VARCHAR(10),
    aircraft_type_code  VARCHAR(10),       -- Depends on aircraft_reg, NOT flight_id
    manufacturer        VARCHAR(60),       -- Depends on type_code, NOT flight_id
    model               VARCHAR(60),       -- Depends on type_code, NOT flight_id
    max_passengers      INT,               -- Depends on type_code, NOT flight_id
    origin              VARCHAR(4),
    destination         VARCHAR(4),
    departure           DATETIME,
    arrival             DATETIME,
    price               DECIMAL(10,2)
);

-- Insert sample denormalized data
INSERT INTO flight_details_denorm VALUES
(1, 'TK1', 'TK', 'Turkish Airlines', 'Turkey', 'TC-JFK', 'B737', 'Boeing', '737-800', 189, 'SKP', 'JFK', '2026-06-14 08:00:00', '2026-06-14 15:30:00', 450.00),
(2, 'TK2', 'TK', 'Turkish Airlines', 'Turkey', 'TC-LNA', 'B777', 'Boeing', '777-300ER', 396, 'SKP', 'LHR', '2026-06-14 09:30:00', '2026-06-14 12:00:00', 320.00),
(4, 'LH400', 'LH', 'Lufthansa', 'Germany', 'D-ABCD', 'A320', 'Airbus', 'A320neo', 194, 'SKP', 'FRA', '2026-06-14 07:15:00', '2026-06-14 09:45:00', 280.00);

-- Show the anomaly: if we want to rename "Turkish Airlines", we must update multiple rows
SELECT 'ANOMALY DEMO: Turkish Airlines appears in 2 rows - renaming requires multiple updates' AS note;
SELECT flight_id, airline_code, airline_name FROM flight_details_denorm WHERE airline_code = 'TK';

-- AFTER DECOMPOSITION (into 3NF):
-- This is exactly how our actual schema is designed:
--   airlines(airline_id PK, airline_code, airline_name, country)
--   aircraft_types(type_id PK, type_code, manufacturer, model, max_passengers)
--   aircraft(aircraft_id PK, registration_no, airline_id FK, type_id FK)
--   flights(flight_id PK, flight_number, airline_id FK, aircraft_id FK, origin, destination, ...)
--
-- Each non-key attribute depends ONLY on the primary key → 3NF achieved!
-- Also satisfies BCNF since every determinant is a candidate key.

SELECT '=== AFTER 3NF DECOMPOSITION ===' AS header;
SELECT 'airlines table: airline_code → airline_name, country (single source of truth)' AS relation_1;
SELECT 'aircraft_types table: type_code → manufacturer, model, max_passengers' AS relation_2;
SELECT 'aircraft table: registration_no → type_id (FK)' AS relation_3;
SELECT 'flights table: flight_id → flight_number, airline_id (FK), aircraft_id (FK), ...' AS relation_4;


-- ============================================================
-- EXAMPLE 2: Denormalized Employee Contact → BCNF Decomposition
-- ============================================================

-- BEFORE: A denormalized employee info table (NOT in BCNF)
-- employee_info_denorm(emp_id, name, email, dept_name, dept_head, 
--   dept_phone, skill1, skill2, skill3)
--
-- FUNCTIONAL DEPENDENCIES:
--   emp_id → name, email, dept_name
--   dept_name → dept_head, dept_phone    ← dept_name is NOT a superkey → violates BCNF
--   emp_id → skill1, skill2, skill3      ← Multi-valued attributes (violates 1NF too!)
--
-- PROBLEMS:
--   1. dept_name → dept_head is a FD where dept_name is NOT a superkey (violates BCNF)
--   2. Skills stored as separate columns = poor design (what if someone has 4 skills?)
--   3. dept_head stored redundantly for every employee in that department

DROP TABLE IF EXISTS employee_info_denorm;
CREATE TABLE employee_info_denorm (
    emp_id      INT PRIMARY KEY,
    emp_name    VARCHAR(100),
    email       VARCHAR(100),
    dept_name   VARCHAR(50),        -- Determines dept_head → BCNF violation
    dept_head   VARCHAR(100),       -- Depends on dept_name, not emp_id
    dept_phone  VARCHAR(20),        -- Depends on dept_name, not emp_id
    skill1      VARCHAR(50),        -- Multi-valued = 1NF violation
    skill2      VARCHAR(50),
    skill3      VARCHAR(50)
);

INSERT INTO employee_info_denorm VALUES
(17, 'Mehmet Kaya', 'm.kaya@skyport.com', 'RAMP', 'Ahmed Osman', '+90-555-8001', 'Tug', 'Belt Loader', 'GPU'),
(18, 'Carlos Garcia', 'c.garcia@skyport.com', 'CHECK_IN', 'Elif Ozturk', '+90-555-8002', 'Kiosk', 'Printer', NULL),
(19, 'Linda Nguyen', 'l.nguyen@skyport.com', 'CARGO', 'Raj Patel', '+90-555-8003', 'Forklift', 'Dolly', 'ULD Loader'),
(22, 'Raj Patel', 'r.patel@skyport.com', 'CARGO', 'Raj Patel', '+90-555-8003', 'Forklift', 'Dolly', 'Pallet Jack'),
(24, 'Ahmed Osman', 'a.osman@skyport.com', 'RAMP', 'Ahmed Osman', '+90-555-8001', 'Radio', 'GPU', 'Tug');

-- Show the BCNF violation: dept_name → dept_head is redundant
SELECT 'BCNF VIOLATION: dept_head is repeated for every RAMP employee' AS note;
SELECT emp_id, emp_name, dept_name, dept_head, dept_phone FROM employee_info_denorm WHERE dept_name = 'RAMP';

-- AFTER DECOMPOSITION (into BCNF):
-- 
-- R1: employees(emp_id PK, emp_name, email, dept_name FK)
--     FD: emp_id → emp_name, email, dept_name
--     emp_id is a superkey → BCNF ✓
--
-- R2: departments(dept_name PK, dept_head, dept_phone)
--     FD: dept_name → dept_head, dept_phone
--     dept_name is a superkey → BCNF ✓
--
-- R3: employee_skills(emp_id FK, skill VARCHAR)  — composite PK (emp_id, skill)
--     No non-trivial FDs beyond the key → BCNF ✓
--     Also solves the multi-valued attribute problem (now unlimited skills!)

-- This maps to our actual schema:
-- employees table + ground_staff.department + equipment_certified (stored as CSV for simplicity)

SELECT '=== AFTER BCNF DECOMPOSITION ===' AS header;
SELECT 'employees(emp_id PK, name, email, dept_name FK) — emp_id is superkey ✓' AS relation_1;
SELECT 'departments(dept_name PK, dept_head, dept_phone) — dept_name is superkey ✓' AS relation_2;
SELECT 'employee_skills(emp_id, skill) — composite PK, no FD violations ✓' AS relation_3;

-- ============================================================
-- LOSSLESS JOIN VERIFICATION
-- Proving that the decomposition is lossless (can reconstruct original)
-- ============================================================

SELECT '=== LOSSLESS JOIN TEST ===' AS header;
SELECT 'Original denormalized data can be reconstructed by joining the normalized tables' AS note;

-- Reconstruct flight_details from normalized tables
SELECT 
    f.flight_id,
    f.flight_number,
    a.airline_code,
    a.airline_name,
    a.country AS airline_country,
    ac.registration_no AS aircraft_reg,
    at.type_code AS aircraft_type_code,
    at.manufacturer,
    at.model,
    at.max_passengers,
    f.origin_airport AS origin,
    f.destination_airport AS destination,
    f.scheduled_departure AS departure,
    f.scheduled_arrival AS arrival,
    f.base_price AS price
FROM flights f
JOIN airlines a ON f.airline_id = a.airline_id
JOIN aircraft ac ON f.aircraft_id = ac.aircraft_id
JOIN aircraft_types at ON ac.type_id = at.type_id
WHERE f.flight_id IN (1, 2, 4);

-- ============================================================
-- DEPENDENCY PRESERVATION VERIFICATION
-- ============================================================

SELECT '=== DEPENDENCY PRESERVATION ===' AS header;
SELECT 'All original FDs can be checked within individual decomposed relations:' AS note;
SELECT '  flight_id → flight_number: checked in flights table' AS fd1;
SELECT '  airline_code → airline_name, country: checked in airlines table' AS fd2;
SELECT '  type_code → manufacturer, model: checked in aircraft_types table' AS fd3;
SELECT '  registration_no → type_id: checked in aircraft table' AS fd4;

-- Cleanup demo tables
-- DROP TABLE IF EXISTS flight_details_denorm;
-- DROP TABLE IF EXISTS employee_info_denorm;
