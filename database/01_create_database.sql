-- ============================================================
-- SKYPORT INTERNATIONAL AIRPORT DATABASE
-- 01_create_database.sql — Schema & Table Creation
-- ============================================================

DROP DATABASE IF EXISTS skyport_airport;
CREATE DATABASE skyport_airport
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE skyport_airport;

-- ============================================================
-- CORE AVIATION ENTITIES
-- ============================================================

-- Airlines
CREATE TABLE airlines (
    airline_id      INT AUTO_INCREMENT PRIMARY KEY,
    airline_code    CHAR(2) NOT NULL UNIQUE,           -- IATA code (TK, LH, BA…)
    airline_name    VARCHAR(100) NOT NULL,
    country         VARCHAR(60) NOT NULL,
    headquarters    VARCHAR(100),
    founded_year    YEAR,
    alliance        ENUM('Star Alliance','Oneworld','SkyTeam','None') DEFAULT 'None',
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Aircraft Types (Boeing 737, Airbus A320, etc.)
CREATE TABLE aircraft_types (
    type_id             INT AUTO_INCREMENT PRIMARY KEY,
    type_code           VARCHAR(10) NOT NULL UNIQUE,    -- B737, A320, etc.
    manufacturer        VARCHAR(60) NOT NULL,
    model               VARCHAR(60) NOT NULL,
    max_passengers      INT NOT NULL,
    max_cargo_kg        DECIMAL(10,2),
    max_range_km        INT,
    cruise_speed_kmh    INT,
    engine_type         ENUM('Jet','Turboprop','Piston') DEFAULT 'Jet',
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Individual Aircraft
CREATE TABLE aircraft (
    aircraft_id         INT AUTO_INCREMENT PRIMARY KEY,
    registration_no     VARCHAR(10) NOT NULL UNIQUE,    -- TC-JFK, D-ABCD…
    airline_id          INT NOT NULL,
    type_id             INT NOT NULL,
    manufacture_year    YEAR NOT NULL,
    total_flight_hours  DECIMAL(10,1) DEFAULT 0,
    status              ENUM('ACTIVE','MAINTENANCE','RETIRED','GROUNDED') DEFAULT 'ACTIVE',
    last_maintenance    DATE,
    next_maintenance    DATE,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (airline_id) REFERENCES airlines(airline_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (type_id) REFERENCES aircraft_types(type_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- AIRPORT INFRASTRUCTURE
-- ============================================================

-- Terminals
CREATE TABLE terminals (
    terminal_id     INT AUTO_INCREMENT PRIMARY KEY,
    terminal_name   VARCHAR(10) NOT NULL UNIQUE,       -- Terminal A, B, C…
    floor_count     INT DEFAULT 2,
    has_lounge      BOOLEAN DEFAULT FALSE,
    has_duty_free   BOOLEAN DEFAULT TRUE,
    status          ENUM('OPEN','CLOSED','MAINTENANCE') DEFAULT 'OPEN',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Gates
CREATE TABLE gates (
    gate_id         INT AUTO_INCREMENT PRIMARY KEY,
    gate_number     VARCHAR(5) NOT NULL,                -- A1, A2, B1…
    terminal_id     INT NOT NULL,
    gate_type       ENUM('DOMESTIC','INTERNATIONAL','BOTH') DEFAULT 'BOTH',
    is_available    BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_gate_terminal (gate_number, terminal_id),
    FOREIGN KEY (terminal_id) REFERENCES terminals(terminal_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Runways
CREATE TABLE runways (
    runway_id       INT AUTO_INCREMENT PRIMARY KEY,
    runway_code     VARCHAR(10) NOT NULL UNIQUE,        -- 06L/24R
    length_meters   INT NOT NULL,
    width_meters    INT NOT NULL,
    surface_type    ENUM('ASPHALT','CONCRETE','GRASS') DEFAULT 'ASPHALT',
    is_active       BOOLEAN DEFAULT TRUE,
    status          ENUM('OPEN','CLOSED','MAINTENANCE') DEFAULT 'OPEN',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- FLIGHTS
-- ============================================================

CREATE TABLE flights (
    flight_id               INT AUTO_INCREMENT PRIMARY KEY,
    flight_number           VARCHAR(10) NOT NULL,           -- TK1234
    airline_id              INT NOT NULL,
    aircraft_id             INT,
    origin_airport          VARCHAR(4) NOT NULL,             -- IATA/ICAO code
    destination_airport     VARCHAR(4) NOT NULL,
    scheduled_departure     DATETIME NOT NULL,
    scheduled_arrival       DATETIME NOT NULL,
    actual_departure        DATETIME,
    actual_arrival          DATETIME,
    flight_type             ENUM('DOMESTIC','INTERNATIONAL') NOT NULL,
    status                  ENUM('SCHEDULED','BOARDING','DEPARTED','IN_AIR','LANDED','ARRIVED','DELAYED','CANCELLED') DEFAULT 'SCHEDULED',
    delay_minutes           INT DEFAULT 0,
    delay_reason            VARCHAR(200),
    runway_id               INT,
    total_seats             INT NOT NULL,
    available_seats         INT NOT NULL,
    base_price              DECIMAL(10,2) NOT NULL,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_flight_number (flight_number),
    INDEX idx_departure (scheduled_departure),
    INDEX idx_status (status),
    FOREIGN KEY (airline_id) REFERENCES airlines(airline_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (aircraft_id) REFERENCES aircraft(aircraft_id) ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (runway_id) REFERENCES runways(runway_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Gate Assignments
CREATE TABLE gate_assignments (
    assignment_id   INT AUTO_INCREMENT PRIMARY KEY,
    flight_id       INT NOT NULL,
    gate_id         INT NOT NULL,
    assignment_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    start_time      DATETIME NOT NULL,
    end_time        DATETIME NOT NULL,
    status          ENUM('ACTIVE','COMPLETED','CANCELLED') DEFAULT 'ACTIVE',
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (gate_id) REFERENCES gates(gate_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Flight Status History (audit)
CREATE TABLE flight_status_history (
    history_id      INT AUTO_INCREMENT PRIMARY KEY,
    flight_id       INT NOT NULL,
    old_status      VARCHAR(20),
    new_status      VARCHAR(20) NOT NULL,
    changed_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by      VARCHAR(100) DEFAULT 'SYSTEM',
    notes           TEXT,
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- PASSENGERS & BOOKINGS
-- ============================================================

CREATE TABLE passengers (
    passenger_id    INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) UNIQUE,
    phone           VARCHAR(20),
    passport_number VARCHAR(20) UNIQUE,
    nationality     VARCHAR(60),
    date_of_birth   DATE,
    gender          ENUM('M','F','OTHER'),
    address         TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_passenger_name (last_name, first_name),
    INDEX idx_passport (passport_number)
) ENGINE=InnoDB;

-- Frequent Flyer Program
CREATE TABLE frequent_flyer (
    ff_id           INT AUTO_INCREMENT PRIMARY KEY,
    passenger_id    INT NOT NULL UNIQUE,
    airline_id      INT NOT NULL,
    ff_number       VARCHAR(20) NOT NULL UNIQUE,
    tier            ENUM('BASIC','SILVER','GOLD','PLATINUM') DEFAULT 'BASIC',
    total_miles     INT DEFAULT 0,
    available_miles INT DEFAULT 0,
    join_date       DATE NOT NULL,
    last_activity   DATE,
    FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (airline_id) REFERENCES airlines(airline_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Bookings
CREATE TABLE bookings (
    booking_id      INT AUTO_INCREMENT PRIMARY KEY,
    booking_ref     VARCHAR(6) NOT NULL UNIQUE,        -- PNR code
    passenger_id    INT NOT NULL,
    flight_id       INT NOT NULL,
    booking_class   ENUM('ECONOMY','PREMIUM_ECONOMY','BUSINESS','FIRST') DEFAULT 'ECONOMY',
    seat_number     VARCHAR(4),                         -- 12A, 3F…
    price           DECIMAL(10,2) NOT NULL,
    booking_status  ENUM('CONFIRMED','CANCELLED','CHECKED_IN','BOARDED','NO_SHOW') DEFAULT 'CONFIRMED',
    payment_status  ENUM('PENDING','PAID','REFUNDED') DEFAULT 'PENDING',
    booking_date    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    special_requests TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_booking_ref (booking_ref),
    INDEX idx_booking_status (booking_status),
    FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Boarding Passes
CREATE TABLE boarding_passes (
    pass_id         INT AUTO_INCREMENT PRIMARY KEY,
    booking_id      INT NOT NULL,
    gate_id         INT,
    boarding_group  CHAR(1),                            -- A, B, C…
    boarding_time   DATETIME,
    barcode         VARCHAR(30) UNIQUE,
    is_boarded      BOOLEAN DEFAULT FALSE,
    issued_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (gate_id) REFERENCES gates(gate_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- BAGGAGE & CARGO
-- ============================================================

CREATE TABLE baggage (
    baggage_id      INT AUTO_INCREMENT PRIMARY KEY,
    booking_id      INT NOT NULL,
    tag_number      VARCHAR(10) NOT NULL UNIQUE,        -- Baggage tag
    weight_kg       DECIMAL(5,2) NOT NULL,
    baggage_type    ENUM('CARRY_ON','CHECKED','OVERSIZED','SPECIAL') DEFAULT 'CHECKED',
    status          ENUM('CHECKED_IN','LOADED','IN_TRANSIT','ARRIVED','CLAIMED','LOST','DAMAGED') DEFAULT 'CHECKED_IN',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Baggage Claims (lost/damaged)
CREATE TABLE baggage_claims (
    claim_id        INT AUTO_INCREMENT PRIMARY KEY,
    baggage_id      INT NOT NULL,
    passenger_id    INT NOT NULL,
    claim_type      ENUM('LOST','DAMAGED','DELAYED') NOT NULL,
    description     TEXT,
    claim_status    ENUM('OPEN','INVESTIGATING','RESOLVED','CLOSED') DEFAULT 'OPEN',
    compensation    DECIMAL(10,2) DEFAULT 0.00,
    filed_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at     DATETIME,
    FOREIGN KEY (baggage_id) REFERENCES baggage(baggage_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Cargo Shipments
CREATE TABLE cargo_shipments (
    shipment_id     INT AUTO_INCREMENT PRIMARY KEY,
    flight_id       INT NOT NULL,
    shipper_name    VARCHAR(100) NOT NULL,
    receiver_name   VARCHAR(100) NOT NULL,
    description     VARCHAR(200),
    weight_kg       DECIMAL(10,2) NOT NULL,
    volume_m3       DECIMAL(8,3),
    shipment_type   ENUM('GENERAL','PERISHABLE','HAZARDOUS','LIVE_ANIMAL','VALUABLE') DEFAULT 'GENERAL',
    status          ENUM('BOOKED','RECEIVED','LOADED','IN_TRANSIT','ARRIVED','DELIVERED') DEFAULT 'BOOKED',
    price           DECIMAL(10,2) NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- EMPLOYEES (BASE TABLE) — INHERITANCE PATTERN
-- ============================================================

CREATE TABLE employees (
    employee_id     INT AUTO_INCREMENT PRIMARY KEY,
    first_name      VARCHAR(50) NOT NULL,
    last_name       VARCHAR(50) NOT NULL,
    email           VARCHAR(100) NOT NULL UNIQUE,
    phone           VARCHAR(20),
    date_of_birth   DATE,
    gender          ENUM('M','F','OTHER'),
    hire_date       DATE NOT NULL,
    salary          DECIMAL(10,2) NOT NULL,
    employee_type   ENUM('PILOT','CABIN_CREW','GROUND_STAFF','SECURITY') NOT NULL,
    airline_id      INT,                                -- NULL for airport staff
    is_active       BOOLEAN DEFAULT TRUE,
    address         TEXT,
    emergency_contact VARCHAR(100),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_employee_type (employee_type),
    FOREIGN KEY (airline_id) REFERENCES airlines(airline_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- PILOTS (inherits from employees)
CREATE TABLE pilots (
    pilot_id            INT PRIMARY KEY,
    license_number      VARCHAR(20) NOT NULL UNIQUE,
    license_type        ENUM('ATPL','CPL','PPL') NOT NULL,  -- Airline Transport, Commercial, Private
    total_flight_hours  DECIMAL(10,1) DEFAULT 0,
    rating              VARCHAR(100),                        -- Type ratings (B737, A320…)
    medical_expiry      DATE NOT NULL,
    last_check_ride     DATE,
    FOREIGN KEY (pilot_id) REFERENCES employees(employee_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- CABIN CREW (inherits from employees)
CREATE TABLE cabin_crew (
    crew_id             INT PRIMARY KEY,
    position            ENUM('PURSER','SENIOR_ATTENDANT','ATTENDANT','TRAINEE') NOT NULL,
    languages_spoken    VARCHAR(200),                        -- e.g. "English,Turkish,German"
    certification_level ENUM('BASIC','ADVANCED','INSTRUCTOR') DEFAULT 'BASIC',
    first_aid_certified BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (crew_id) REFERENCES employees(employee_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- GROUND STAFF (inherits from employees)
CREATE TABLE ground_staff (
    staff_id            INT PRIMARY KEY,
    department          ENUM('RAMP','CHECK_IN','CARGO','CUSTOMER_SERVICE','OPERATIONS') NOT NULL,
    equipment_certified VARCHAR(200),                        -- Forklift, tug, belt loader…
    shift_pattern       ENUM('MORNING','AFTERNOON','NIGHT','ROTATING') DEFAULT 'ROTATING',
    terminal_assigned   INT,
    FOREIGN KEY (staff_id) REFERENCES employees(employee_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (terminal_assigned) REFERENCES terminals(terminal_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- SECURITY PERSONNEL (inherits from employees)
CREATE TABLE security_personnel (
    security_id         INT PRIMARY KEY,
    clearance_level     ENUM('BASIC','ELEVATED','TOP_SECRET') NOT NULL,
    badge_number        VARCHAR(10) NOT NULL UNIQUE,
    assigned_zone       VARCHAR(50),                         -- Terminal A, Cargo, Perimeter…
    weapon_certified    BOOLEAN DEFAULT FALSE,
    last_training       DATE,
    FOREIGN KEY (security_id) REFERENCES employees(employee_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- FLIGHT CREW ASSIGNMENTS
-- ============================================================

CREATE TABLE flight_crew_assignments (
    assignment_id   INT AUTO_INCREMENT PRIMARY KEY,
    flight_id       INT NOT NULL,
    employee_id     INT NOT NULL,
    role            ENUM('CAPTAIN','FIRST_OFFICER','PURSER','CABIN_CREW') NOT NULL,
    assigned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_flight_crew (flight_id, employee_id),
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- MAINTENANCE
-- ============================================================

CREATE TABLE maintenance_records (
    record_id       INT AUTO_INCREMENT PRIMARY KEY,
    aircraft_id     INT NOT NULL,
    maintenance_type ENUM('ROUTINE','REPAIR','INSPECTION','OVERHAUL','EMERGENCY') NOT NULL,
    description     TEXT NOT NULL,
    start_date      DATETIME NOT NULL,
    end_date        DATETIME,
    performed_by    INT,                                     -- employee_id
    status          ENUM('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED') DEFAULT 'SCHEDULED',
    cost            DECIMAL(12,2),
    parts_replaced  TEXT,
    notes           TEXT,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (aircraft_id) REFERENCES aircraft(aircraft_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (performed_by) REFERENCES employees(employee_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- PARKING
-- ============================================================

CREATE TABLE parking_lots (
    lot_id          INT AUTO_INCREMENT PRIMARY KEY,
    lot_name        VARCHAR(30) NOT NULL UNIQUE,
    lot_type        ENUM('SHORT_TERM','LONG_TERM','VIP','EMPLOYEE') NOT NULL,
    total_spots     INT NOT NULL,
    available_spots INT NOT NULL,
    hourly_rate     DECIMAL(6,2) NOT NULL,
    daily_max       DECIMAL(8,2),
    terminal_id     INT,
    is_covered      BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (terminal_id) REFERENCES terminals(terminal_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE parking_reservations (
    reservation_id  INT AUTO_INCREMENT PRIMARY KEY,
    lot_id          INT NOT NULL,
    passenger_id    INT,
    license_plate   VARCHAR(15) NOT NULL,
    entry_time      DATETIME NOT NULL,
    exit_time       DATETIME,
    total_charge    DECIMAL(8,2) DEFAULT 0.00,
    status          ENUM('ACTIVE','COMPLETED','CANCELLED') DEFAULT 'ACTIVE',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lot_id) REFERENCES parking_lots(lot_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- COMMERCIAL (SHOPS)
-- ============================================================

CREATE TABLE shops (
    shop_id         INT AUTO_INCREMENT PRIMARY KEY,
    shop_name       VARCHAR(100) NOT NULL,
    shop_type       ENUM('DUTY_FREE','RESTAURANT','CAFE','FASHION','ELECTRONICS','BOOKSTORE','PHARMACY','LOUNGE') NOT NULL,
    terminal_id     INT NOT NULL,
    floor_number    INT DEFAULT 1,
    opening_time    TIME NOT NULL,
    closing_time    TIME NOT NULL,
    is_active       BOOLEAN DEFAULT TRUE,
    monthly_rent    DECIMAL(10,2),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (terminal_id) REFERENCES terminals(terminal_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE shop_transactions (
    transaction_id  INT AUTO_INCREMENT PRIMARY KEY,
    shop_id         INT NOT NULL,
    passenger_id    INT,
    amount          DECIMAL(10,2) NOT NULL,
    payment_method  ENUM('CASH','CREDIT_CARD','DEBIT_CARD','MILES') NOT NULL,
    items_purchased TEXT,
    transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (shop_id) REFERENCES shops(shop_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (passenger_id) REFERENCES passengers(passenger_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ============================================================
-- AUDIT LOG
-- ============================================================

CREATE TABLE audit_log (
    log_id          INT AUTO_INCREMENT PRIMARY KEY,
    table_name      VARCHAR(50) NOT NULL,
    operation       ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    record_id       INT,
    old_values      JSON,
    new_values      JSON,
    performed_by    VARCHAR(100) DEFAULT 'SYSTEM',
    performed_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_table (table_name),
    INDEX idx_audit_time (performed_at)
) ENGINE=InnoDB;

-- ============================================================
-- END OF SCHEMA
-- ============================================================
