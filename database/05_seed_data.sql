-- ============================================================
-- SKYPORT INTERNATIONAL AIRPORT DATABASE
-- 05_seed_data.sql — Realistic Mock Data
-- ============================================================

USE skyport_airport;

-- ============================================================
-- AIRLINES (8 airlines)
-- ============================================================
INSERT INTO airlines (airline_code, airline_name, country, headquarters, founded_year, alliance) VALUES
('TK', 'Turkish Airlines', 'Turkey', 'Istanbul', 1933, 'Star Alliance'),
('LH', 'Lufthansa', 'Germany', 'Cologne', 1953, 'Star Alliance'),
('BA', 'British Airways', 'United Kingdom', 'London', 1974, 'Oneworld'),
('AF', 'Air France', 'France', 'Paris', 1933, 'SkyTeam'),
('EK', 'Emirates', 'UAE', 'Dubai', 1985, 'None'),
('QR', 'Qatar Airways', 'Qatar', 'Doha', 1993, 'Oneworld'),
('SQ', 'Singapore Airlines', 'Singapore', 'Singapore', 1947, 'Star Alliance'),
('DL', 'Delta Air Lines', 'USA', 'Atlanta', 1924, 'SkyTeam');

-- ============================================================
-- AIRCRAFT TYPES (6 types)
-- ============================================================
INSERT INTO aircraft_types (type_code, manufacturer, model, max_passengers, max_cargo_kg, max_range_km, cruise_speed_kmh, engine_type) VALUES
('B737', 'Boeing', '737-800', 189, 20000.00, 5765, 842, 'Jet'),
('B777', 'Boeing', '777-300ER', 396, 60000.00, 13650, 905, 'Jet'),
('A320', 'Airbus', 'A320neo', 194, 16600.00, 6300, 833, 'Jet'),
('A330', 'Airbus', 'A330-300', 440, 45000.00, 11750, 871, 'Jet'),
('B787', 'Boeing', '787-9 Dreamliner', 296, 38000.00, 14140, 903, 'Jet'),
('A380', 'Airbus', 'A380-800', 853, 80000.00, 15200, 903, 'Jet');

-- ============================================================
-- AIRCRAFT (16 aircraft)
-- ============================================================
INSERT INTO aircraft (registration_no, airline_id, type_id, manufacture_year, total_flight_hours, status, last_maintenance, next_maintenance) VALUES
('TC-JFK', 1, 1, 2015, 28500.5, 'ACTIVE', '2026-05-15', '2026-08-15'),
('TC-LNA', 1, 2, 2018, 19200.0, 'ACTIVE', '2026-04-20', '2026-07-20'),
('TC-JSK', 1, 5, 2020, 12000.0, 'ACTIVE', '2026-06-01', '2026-09-01'),
('TC-JOE', 1, 3, 2019, 15600.0, 'MAINTENANCE', '2026-06-10', '2026-09-10'),
('D-ABCD', 2, 3, 2017, 22000.0, 'ACTIVE', '2026-05-01', '2026-08-01'),
('D-AXYZ', 2, 4, 2016, 25000.0, 'ACTIVE', '2026-04-15', '2026-07-15'),
('G-BOAC', 3, 2, 2019, 17500.0, 'ACTIVE', '2026-05-20', '2026-08-20'),
('G-BNLY', 3, 1, 2014, 31000.0, 'ACTIVE', '2026-03-10', '2026-06-10'),
('F-GKXJ', 4, 3, 2018, 20100.0, 'ACTIVE', '2026-05-05', '2026-08-05'),
('F-HTAB', 4, 4, 2020, 11500.0, 'ACTIVE', '2026-06-05', '2026-09-05'),
('A6-EWA', 5, 6, 2017, 26000.0, 'ACTIVE', '2026-04-01', '2026-07-01'),
('A6-EPC', 5, 2, 2021, 9500.0, 'ACTIVE', '2026-06-08', '2026-09-08'),
('A7-BCA', 6, 5, 2022, 7200.0, 'ACTIVE', '2026-05-25', '2026-08-25'),
('9V-SKA', 7, 6, 2019, 18000.0, 'ACTIVE', '2026-04-10', '2026-07-10'),
('N501DL', 8, 1, 2016, 24500.0, 'ACTIVE', '2026-05-10', '2026-08-10'),
('N802DN', 8, 5, 2021, 10000.0, 'GROUNDED', '2026-06-12', '2026-09-12');

-- ============================================================
-- TERMINALS (4 terminals)
-- ============================================================
INSERT INTO terminals (terminal_name, floor_count, has_lounge, has_duty_free, status) VALUES
('Terminal A', 3, TRUE, TRUE, 'OPEN'),
('Terminal B', 2, TRUE, TRUE, 'OPEN'),
('Terminal C', 3, TRUE, TRUE, 'OPEN'),
('Terminal D', 2, FALSE, TRUE, 'OPEN');

-- ============================================================
-- GATES (20 gates)
-- ============================================================
INSERT INTO gates (gate_number, terminal_id, gate_type, is_available) VALUES
('A1', 1, 'INTERNATIONAL', TRUE), ('A2', 1, 'INTERNATIONAL', TRUE),
('A3', 1, 'INTERNATIONAL', TRUE), ('A4', 1, 'BOTH', TRUE),
('A5', 1, 'BOTH', TRUE),
('B1', 2, 'DOMESTIC', TRUE), ('B2', 2, 'DOMESTIC', TRUE),
('B3', 2, 'DOMESTIC', TRUE), ('B4', 2, 'BOTH', TRUE),
('B5', 2, 'BOTH', TRUE),
('C1', 3, 'INTERNATIONAL', TRUE), ('C2', 3, 'INTERNATIONAL', TRUE),
('C3', 3, 'INTERNATIONAL', TRUE), ('C4', 3, 'BOTH', TRUE),
('C5', 3, 'BOTH', TRUE),
('D1', 4, 'DOMESTIC', TRUE), ('D2', 4, 'DOMESTIC', TRUE),
('D3', 4, 'DOMESTIC', TRUE), ('D4', 4, 'BOTH', TRUE),
('D5', 4, 'BOTH', TRUE);

-- ============================================================
-- RUNWAYS (3 runways)
-- ============================================================
INSERT INTO runways (runway_code, length_meters, width_meters, surface_type, is_active, status) VALUES
('06L/24R', 3600, 60, 'ASPHALT', TRUE, 'OPEN'),
('06R/24L', 3000, 45, 'CONCRETE', TRUE, 'OPEN'),
('17/35', 2800, 45, 'ASPHALT', TRUE, 'OPEN');

-- ============================================================
-- FLIGHTS (20 flights)
-- ============================================================
INSERT INTO flights (flight_number, airline_id, aircraft_id, origin_airport, destination_airport, scheduled_departure, scheduled_arrival, actual_departure, actual_arrival, flight_type, status, delay_minutes, delay_reason, runway_id, total_seats, available_seats, base_price) VALUES
('TK1', 1, 1, 'SKP', 'JFK', '2026-06-14 08:00:00', '2026-06-14 15:30:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 1, 189, 145, 450.00),
('TK2', 1, 2, 'SKP', 'LHR', '2026-06-14 09:30:00', '2026-06-14 12:00:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 1, 396, 310, 320.00),
('TK100', 1, 3, 'SKP', 'DXB', '2026-06-14 14:00:00', '2026-06-14 20:30:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 2, 296, 250, 380.00),
('LH400', 2, 5, 'SKP', 'FRA', '2026-06-14 07:15:00', '2026-06-14 09:45:00', NULL, NULL, 'INTERNATIONAL', 'BOARDING', 0, NULL, 1, 194, 120, 280.00),
('LH401', 2, 6, 'FRA', 'SKP', '2026-06-14 16:00:00', '2026-06-14 18:30:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 2, 440, 380, 280.00),
('BA300', 3, 7, 'SKP', 'LHR', '2026-06-14 11:00:00', '2026-06-14 13:30:00', NULL, NULL, 'INTERNATIONAL', 'DELAYED', 45, 'Weather conditions', 1, 396, 290, 350.00),
('BA301', 3, 8, 'LHR', 'SKP', '2026-06-14 18:00:00', '2026-06-14 23:30:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 3, 189, 160, 350.00),
('AF500', 4, 9, 'SKP', 'CDG', '2026-06-14 06:30:00', '2026-06-14 09:00:00', '2026-06-14 06:35:00', '2026-06-14 09:05:00', 'INTERNATIONAL', 'ARRIVED', 5, NULL, 2, 194, 80, 300.00),
('AF501', 4, 10, 'CDG', 'SKP', '2026-06-14 15:00:00', '2026-06-14 17:30:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 1, 440, 400, 300.00),
('EK700', 5, 11, 'SKP', 'DXB', '2026-06-14 22:00:00', '2026-06-15 05:30:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 1, 853, 750, 500.00),
('EK701', 5, 12, 'DXB', 'SKP', '2026-06-14 10:00:00', '2026-06-14 14:30:00', NULL, NULL, 'INTERNATIONAL', 'IN_AIR', 0, NULL, 2, 396, 280, 500.00),
('QR800', 6, 13, 'SKP', 'DOH', '2026-06-14 01:30:00', '2026-06-14 07:00:00', '2026-06-14 01:30:00', '2026-06-14 07:05:00', 'INTERNATIONAL', 'ARRIVED', 0, NULL, 3, 296, 190, 420.00),
('SQ900', 7, 14, 'SKP', 'SIN', '2026-06-14 23:00:00', '2026-06-15 17:30:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 1, 853, 780, 680.00),
('DL200', 8, 15, 'SKP', 'ATL', '2026-06-14 12:00:00', '2026-06-14 19:30:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 2, 189, 100, 520.00),
('TK50', 1, 1, 'SKP', 'ADB', '2026-06-15 07:00:00', '2026-06-15 08:15:00', NULL, NULL, 'DOMESTIC', 'SCHEDULED', 0, NULL, 3, 189, 170, 80.00),
('TK52', 1, 3, 'SKP', 'AYT', '2026-06-15 09:00:00', '2026-06-15 10:30:00', NULL, NULL, 'DOMESTIC', 'SCHEDULED', 0, NULL, 1, 296, 260, 95.00),
('TK54', 1, 2, 'SKP', 'ESB', '2026-06-15 11:00:00', '2026-06-15 12:15:00', NULL, NULL, 'DOMESTIC', 'SCHEDULED', 0, NULL, 2, 396, 370, 70.00),
('BA302', 3, 7, 'SKP', 'LHR', '2026-06-15 11:00:00', '2026-06-15 13:30:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 1, 396, 380, 350.00),
('EK702', 5, 11, 'DXB', 'SKP', '2026-06-15 08:00:00', '2026-06-15 12:30:00', NULL, NULL, 'INTERNATIONAL', 'SCHEDULED', 0, NULL, 3, 853, 820, 500.00),
('TK3', 1, 3, 'SKP', 'CDG', '2026-06-14 16:30:00', '2026-06-14 19:00:00', NULL, NULL, 'INTERNATIONAL', 'CANCELLED', 0, 'Technical issue', 1, 296, 296, 310.00);

-- ============================================================
-- PASSENGERS (25 passengers)
-- ============================================================
INSERT INTO passengers (first_name, last_name, email, phone, passport_number, nationality, date_of_birth, gender, address) VALUES
('James', 'Anderson', 'james.anderson@email.com', '+1-555-0101', 'US12345678', 'American', '1985-03-15', 'M', '42 Oak Street, New York, NY 10001'),
('Sophie', 'Mueller', 'sophie.mueller@email.com', '+49-555-0102', 'DE87654321', 'German', '1990-07-22', 'F', '15 Berliner Str, Berlin, 10115'),
('Ahmet', 'Yilmaz', 'ahmet.yilmaz@email.com', '+90-555-0103', 'TR11223344', 'Turkish', '1988-11-03', 'M', 'Istiklal Cad 78, Istanbul, 34000'),
('Emma', 'Thompson', 'emma.thompson@email.com', '+44-555-0104', 'GB55667788', 'British', '1992-01-28', 'F', '22 Baker Street, London, W1U 3BW'),
('Mohammed', 'Al-Rashid', 'mohammed.rashid@email.com', '+971-555-0105', 'AE99887766', 'Emirati', '1982-05-10', 'M', 'Sheikh Zayed Rd, Dubai, UAE'),
('Marie', 'Dubois', 'marie.dubois@email.com', '+33-555-0106', 'FR44332211', 'French', '1995-09-14', 'F', '8 Rue de Rivoli, Paris, 75001'),
('Kenji', 'Tanaka', 'kenji.tanaka@email.com', '+81-555-0107', 'JP66778899', 'Japanese', '1987-12-05', 'M', '3-1-1 Shibuya, Tokyo, 150-0002'),
('Isabella', 'Rodriguez', 'isabella.rodriguez@email.com', '+34-555-0108', 'ES11335577', 'Spanish', '1991-04-17', 'F', 'Gran Via 25, Madrid, 28013'),
('Chen', 'Wei', 'chen.wei@email.com', '+86-555-0109', 'CN22446688', 'Chinese', '1989-08-30', 'M', '100 Nanjing Rd, Shanghai, 200000'),
('Anna', 'Petrova', 'anna.petrova@email.com', '+7-555-0110', 'RU33557799', 'Russian', '1993-06-21', 'F', 'Nevsky Prospekt 50, St Petersburg'),
('Lucas', 'Silva', 'lucas.silva@email.com', '+55-555-0111', 'BR44668800', 'Brazilian', '1986-02-14', 'M', 'Av Paulista 1000, Sao Paulo'),
('Fatima', 'Hassan', 'fatima.hassan@email.com', '+974-555-0112', 'QA55779911', 'Qatari', '1994-10-08', 'F', 'Al Corniche, Doha, Qatar'),
('Oliver', 'Brown', 'oliver.brown@email.com', '+61-555-0113', 'AU66880022', 'Australian', '1983-07-19', 'M', '123 George St, Sydney, NSW 2000'),
('Priya', 'Sharma', 'priya.sharma@email.com', '+91-555-0114', 'IN77991133', 'Indian', '1996-03-25', 'F', 'MG Road, Bangalore, 560001'),
('Erik', 'Johansson', 'erik.johansson@email.com', '+46-555-0115', 'SE88002244', 'Swedish', '1984-11-30', 'M', 'Drottninggatan 10, Stockholm'),
('Yuki', 'Sato', 'yuki.sato@email.com', '+81-555-0116', 'JP99113355', 'Japanese', '1997-08-12', 'F', '1-1-1 Ginza, Tokyo, 104-0061'),
('Marco', 'Rossi', 'marco.rossi@email.com', '+39-555-0117', 'IT00224466', 'Italian', '1990-05-07', 'M', 'Via Roma 15, Rome, 00184'),
('Sarah', 'Williams', 'sarah.williams@email.com', '+1-555-0118', 'US11335580', 'American', '1988-09-23', 'F', '88 Fifth Ave, New York, NY 10011'),
('Ali', 'Demir', 'ali.demir@email.com', '+90-555-0119', 'TR22446690', 'Turkish', '1985-12-01', 'M', 'Bagdat Cad 120, Istanbul, 34710'),
('Nina', 'Kowalski', 'nina.kowalski@email.com', '+48-555-0120', 'PL33557701', 'Polish', '1992-04-16', 'F', 'Nowy Swiat 22, Warsaw, 00-373'),
('David', 'Kim', 'david.kim@email.com', '+82-555-0121', 'KR44668812', 'Korean', '1991-01-09', 'M', 'Gangnam-gu, Seoul, 06000'),
('Laura', 'Martinez', 'laura.martinez@email.com', '+52-555-0122', 'MX55779923', 'Mexican', '1993-07-28', 'F', 'Reforma 222, Mexico City'),
('Hans', 'Weber', 'hans.weber@email.com', '+49-555-0123', 'DE66880034', 'German', '1980-10-15', 'M', 'Maximilianstr 8, Munich, 80539'),
('Aisha', 'Khan', 'aisha.khan@email.com', '+92-555-0124', 'PK77991145', 'Pakistani', '1995-02-20', 'F', 'Mall Road, Lahore, 54000'),
('Robert', 'Johnson', 'robert.johnson@email.com', '+1-555-0125', 'US88002256', 'American', '1979-06-11', 'M', '200 Michigan Ave, Chicago, IL 60601');

-- ============================================================
-- FREQUENT FLYER (15 members)
-- ============================================================
INSERT INTO frequent_flyer (passenger_id, airline_id, ff_number, tier, total_miles, available_miles, join_date, last_activity) VALUES
(1, 1, 'TK-FF-00001', 'GOLD', 125000, 45000, '2020-01-15', '2026-06-01'),
(2, 2, 'LH-FF-00002', 'SILVER', 68000, 22000, '2021-03-20', '2026-05-15'),
(3, 1, 'TK-FF-00003', 'PLATINUM', 250000, 80000, '2018-06-10', '2026-06-10'),
(4, 3, 'BA-FF-00004', 'GOLD', 110000, 35000, '2019-09-05', '2026-05-20'),
(5, 5, 'EK-FF-00005', 'PLATINUM', 320000, 150000, '2017-01-01', '2026-06-05'),
(6, 4, 'AF-FF-00006', 'SILVER', 55000, 18000, '2022-04-12', '2026-04-30'),
(7, 7, 'SQ-FF-00007', 'GOLD', 95000, 40000, '2020-08-15', '2026-05-25'),
(8, 1, 'TK-FF-00008', 'BASIC', 12000, 8000, '2024-01-20', '2026-03-10'),
(10, 1, 'TK-FF-00010', 'SILVER', 72000, 30000, '2021-07-01', '2026-06-08'),
(13, 3, 'BA-FF-00013', 'BASIC', 25000, 15000, '2023-02-14', '2026-04-22'),
(14, 5, 'EK-FF-00014', 'GOLD', 140000, 60000, '2019-11-30', '2026-06-01'),
(17, 4, 'AF-FF-00017', 'BASIC', 8000, 5000, '2025-01-05', '2026-02-28'),
(19, 1, 'TK-FF-00019', 'GOLD', 105000, 42000, '2020-03-18', '2026-06-12'),
(21, 8, 'DL-FF-00021', 'SILVER', 78000, 28000, '2021-05-22', '2026-05-30'),
(25, 8, 'DL-FF-00025', 'PLATINUM', 290000, 120000, '2016-09-10', '2026-06-09');

-- ============================================================
-- BOOKINGS (30 bookings) — NOTE: triggers will auto-create boarding passes
-- ============================================================
INSERT INTO bookings (booking_ref, passenger_id, flight_id, booking_class, seat_number, price, booking_status, payment_status, special_requests) VALUES
('ABC123', 1, 1, 'BUSINESS', '3A', 1125.00, 'CONFIRMED', 'PAID', 'Vegetarian meal'),
('DEF456', 2, 4, 'ECONOMY', '22B', 280.00, 'CHECKED_IN', 'PAID', NULL),
('GHI789', 3, 1, 'FIRST', '1A', 1800.00, 'CONFIRMED', 'PAID', 'Extra legroom'),
('JKL012', 4, 6, 'BUSINESS', '5C', 875.00, 'CONFIRMED', 'PAID', NULL),
('MNO345', 5, 10, 'FIRST', '1K', 2000.00, 'CONFIRMED', 'PAID', 'Wheelchair assistance'),
('PQR678', 6, 8, 'ECONOMY', '18D', 300.00, 'CHECKED_IN', 'PAID', NULL),
('STU901', 7, 13, 'BUSINESS', '8A', 1700.00, 'CONFIRMED', 'PAID', 'Kosher meal'),
('VWX234', 8, 2, 'ECONOMY', '30F', 320.00, 'CONFIRMED', 'PAID', NULL),
('YZA567', 9, 3, 'ECONOMY', '25C', 380.00, 'CONFIRMED', 'PAID', NULL),
('BCD890', 10, 12, 'BUSINESS', '6B', 1050.00, 'CHECKED_IN', 'PAID', NULL),
('EFG123', 11, 14, 'ECONOMY', '19A', 520.00, 'CONFIRMED', 'PAID', NULL),
('HIJ456', 12, 12, 'FIRST', '2A', 1680.00, 'CHECKED_IN', 'PAID', 'Arabic meal'),
('KLM789', 13, 6, 'ECONOMY', '28E', 350.00, 'CONFIRMED', 'PAID', NULL),
('NOP012', 14, 10, 'BUSINESS', '7J', 1250.00, 'CONFIRMED', 'PAID', 'Hindu meal'),
('QRS345', 15, 4, 'PREMIUM_ECONOMY', '14A', 420.00, 'CONFIRMED', 'PAID', NULL),
('TUV678', 16, 13, 'ECONOMY', '35B', 680.00, 'CONFIRMED', 'PAID', NULL),
('WXY901', 17, 8, 'PREMIUM_ECONOMY', '12C', 450.00, 'CHECKED_IN', 'PAID', NULL),
('ZAB234', 18, 14, 'BUSINESS', '4F', 1300.00, 'CONFIRMED', 'PAID', NULL),
('CDE567', 19, 1, 'ECONOMY', '24D', 450.00, 'CONFIRMED', 'PAID', NULL),
('FGH890', 20, 2, 'ECONOMY', '28A', 320.00, 'CONFIRMED', 'PAID', NULL),
('IJK123', 21, 14, 'ECONOMY', '21C', 520.00, 'CONFIRMED', 'PAID', NULL),
('LMN456', 22, 4, 'BUSINESS', '6A', 700.00, 'CONFIRMED', 'PAID', 'Vegan meal'),
('OPQ789', 23, 3, 'ECONOMY', '32F', 380.00, 'CONFIRMED', 'PAID', NULL),
('RST012', 24, 10, 'ECONOMY', '42B', 500.00, 'CONFIRMED', 'PAID', NULL),
('UVW345', 25, 14, 'FIRST', '1A', 2080.00, 'CONFIRMED', 'PAID', 'Private transfer'),
('XYZ678', 3, 15, 'ECONOMY', '8A', 80.00, 'CONFIRMED', 'PAID', NULL),
('AAB901', 19, 15, 'ECONOMY', '12C', 80.00, 'CONFIRMED', 'PAID', NULL),
('BBC234', 1, 2, 'BUSINESS', '5A', 800.00, 'CONFIRMED', 'PAID', NULL),
('CCD567', 5, 11, 'FIRST', '1F', 2000.00, 'CHECKED_IN', 'PAID', NULL),
('DDE890', 14, 11, 'BUSINESS', '8C', 1250.00, 'CHECKED_IN', 'PAID', NULL);

-- ============================================================
-- GATE ASSIGNMENTS (10 assignments)
-- ============================================================
INSERT INTO gate_assignments (flight_id, gate_id, start_time, end_time, status) VALUES
(1, 1, '2026-06-14 06:30:00', '2026-06-14 08:30:00', 'ACTIVE'),
(2, 3, '2026-06-14 08:00:00', '2026-06-14 10:00:00', 'ACTIVE'),
(3, 11, '2026-06-14 12:30:00', '2026-06-14 14:30:00', 'ACTIVE'),
(4, 2, '2026-06-14 05:45:00', '2026-06-14 07:45:00', 'ACTIVE'),
(6, 4, '2026-06-14 09:30:00', '2026-06-14 11:30:00', 'ACTIVE'),
(8, 12, '2026-06-14 05:00:00', '2026-06-14 07:00:00', 'COMPLETED'),
(10, 13, '2026-06-14 20:30:00', '2026-06-14 22:30:00', 'ACTIVE'),
(12, 14, '2026-06-13 23:30:00', '2026-06-14 02:00:00', 'COMPLETED'),
(13, 5, '2026-06-14 21:30:00', '2026-06-14 23:30:00', 'ACTIVE'),
(14, 15, '2026-06-14 10:30:00', '2026-06-14 12:30:00', 'ACTIVE');

-- ============================================================
-- BAGGAGE (25 items)
-- ============================================================
INSERT INTO baggage (booking_id, tag_number, weight_kg, baggage_type, status) VALUES
(1, 'BG00000001', 18.5, 'CHECKED', 'CHECKED_IN'),
(1, 'BG00000002', 7.2, 'CARRY_ON', 'CHECKED_IN'),
(2, 'BG00000003', 22.0, 'CHECKED', 'LOADED'),
(3, 'BG00000004', 28.5, 'CHECKED', 'CHECKED_IN'),
(3, 'BG00000005', 25.0, 'CHECKED', 'CHECKED_IN'),
(4, 'BG00000006', 15.8, 'CHECKED', 'CHECKED_IN'),
(5, 'BG00000007', 30.0, 'CHECKED', 'CHECKED_IN'),
(5, 'BG00000008', 22.0, 'CHECKED', 'CHECKED_IN'),
(6, 'BG00000009', 20.5, 'CHECKED', 'ARRIVED'),
(6, 'BG00000010', 6.5, 'CARRY_ON', 'ARRIVED'),
(7, 'BG00000011', 18.0, 'CHECKED', 'CHECKED_IN'),
(8, 'BG00000012', 21.0, 'CHECKED', 'CHECKED_IN'),
(9, 'BG00000013', 19.5, 'CHECKED', 'CHECKED_IN'),
(10, 'BG00000014', 23.0, 'CHECKED', 'ARRIVED'),
(11, 'BG00000015', 17.0, 'CHECKED', 'CHECKED_IN'),
(12, 'BG00000016', 35.0, 'CHECKED', 'ARRIVED'),
(13, 'BG00000017', 22.5, 'CHECKED', 'CHECKED_IN'),
(14, 'BG00000018', 26.0, 'CHECKED', 'CHECKED_IN'),
(15, 'BG00000019', 20.0, 'CHECKED', 'LOADED'),
(17, 'BG00000020', 21.5, 'CHECKED', 'ARRIVED'),
(18, 'BG00000021', 24.0, 'CHECKED', 'CHECKED_IN'),
(19, 'BG00000022', 15.0, 'CHECKED', 'CHECKED_IN'),
(20, 'BG00000023', 18.0, 'CHECKED', 'CHECKED_IN'),
(25, 'BG00000024', 32.0, 'CHECKED', 'CHECKED_IN'),
(29, 'BG00000025', 28.0, 'CHECKED', 'LOADED');

-- ============================================================
-- BAGGAGE CLAIMS (3 claims)
-- ============================================================
INSERT INTO baggage_claims (baggage_id, passenger_id, claim_type, description, claim_status, compensation) VALUES
(9, 6, 'DELAYED', 'Baggage did not arrive with the flight. Expected on next connection.', 'INVESTIGATING', 0.00),
(14, 10, 'DAMAGED', 'Suitcase handle broken and scratches on surface.', 'OPEN', 150.00),
(16, 12, 'LOST', 'Luxury Rimowa suitcase not found after flight QR800.', 'INVESTIGATING', 0.00);

-- ============================================================
-- CARGO SHIPMENTS (8 shipments)
-- ============================================================
INSERT INTO cargo_shipments (flight_id, shipper_name, receiver_name, description, weight_kg, volume_m3, shipment_type, status, price) VALUES
(1, 'Tech Solutions Inc.', 'NYC Electronics Ltd.', 'Computer components and peripherals', 850.00, 3.200, 'GENERAL', 'BOOKED', 2500.00),
(2, 'Istanbul Ceramics Co.', 'London Home Decor', 'Handmade ceramic tiles', 1200.00, 4.500, 'GENERAL', 'LOADED', 1800.00),
(3, 'Turkish Delight Exports', 'Dubai Sweets Trading', 'Assorted confectionery products', 500.00, 2.000, 'PERISHABLE', 'BOOKED', 1200.00),
(10, 'Pharma Global', 'Emirates Healthcare', 'Temperature-sensitive vaccines', 200.00, 0.800, 'PERISHABLE', 'BOOKED', 5000.00),
(13, 'Art Gallery Istanbul', 'Singapore Art Museum', 'Valuable paintings (insured)', 150.00, 3.500, 'VALUABLE', 'BOOKED', 8000.00),
(14, 'Auto Parts Turkey', 'Atlanta Motors Inc.', 'Engine components', 2000.00, 6.000, 'GENERAL', 'BOOKED', 3500.00),
(8, 'Paris Fashion House', 'Istanbul Boutique', 'Designer clothing collection', 300.00, 2.500, 'GENERAL', 'DELIVERED', 1500.00),
(12, 'Qatar Marine Supplies', 'Marine Workshop Istanbul', 'Boat engine parts', 800.00, 3.000, 'GENERAL', 'ARRIVED', 2200.00);

-- ============================================================
-- EMPLOYEES (30 employees — 8 pilots, 8 cabin crew, 8 ground staff, 6 security)
-- ============================================================
INSERT INTO employees (first_name, last_name, email, phone, date_of_birth, gender, hire_date, salary, employee_type, airline_id, is_active, address, emergency_contact) VALUES
-- Pilots (IDs 1-8)
('Captain', 'Reynolds', 'c.reynolds@skyport.com', '+1-555-1001', '1975-03-12', 'M', '2005-06-15', 12000.00, 'PILOT', 1, TRUE, '10 Aviation Lane', 'Mary Reynolds +1-555-9001'),
('First Officer', 'Chen', 'fo.chen@skyport.com', '+86-555-1002', '1982-09-28', 'M', '2012-03-20', 9500.00, 'PILOT', 1, TRUE, '22 Pilot Road', 'Lin Chen +86-555-9002'),
('Captain', 'Schmidt', 'c.schmidt@skyport.com', '+49-555-1003', '1978-05-14', 'M', '2008-01-10', 13000.00, 'PILOT', 2, TRUE, '5 Flughafen Str', 'Helga Schmidt +49-555-9003'),
('Captain', 'Williams', 'c.williams@skyport.com', '+44-555-1004', '1980-11-22', 'F', '2010-07-01', 12500.00, 'PILOT', 3, TRUE, '15 Heathrow Rd', 'Tom Williams +44-555-9004'),
('First Officer', 'Dubois', 'fo.dubois@skyport.com', '+33-555-1005', '1985-04-08', 'M', '2015-09-15', 8800.00, 'PILOT', 4, TRUE, '8 Rue CDG', 'Marie Dubois +33-555-9005'),
('Captain', 'Al-Mansour', 'c.almansour@skyport.com', '+971-555-1006', '1976-08-17', 'M', '2006-02-28', 15000.00, 'PILOT', 5, TRUE, 'Palm Jumeirah Villa', 'Sara Al-Mansour +971-555-9006'),
('Captain', 'Nakamura', 'c.nakamura@skyport.com', '+81-555-1007', '1979-01-30', 'M', '2009-11-12', 14000.00, 'PILOT', 7, TRUE, '1-2 Narita Heights', 'Yuki Nakamura +81-555-9007'),
('First Officer', 'Davis', 'fo.davis@skyport.com', '+1-555-1008', '1988-06-25', 'F', '2018-04-01', 8500.00, 'PILOT', 8, TRUE, '55 Hartsfield Dr', 'Mark Davis +1-555-9008'),
-- Cabin Crew (IDs 9-16)
('Elena', 'Volkov', 'e.volkov@skyport.com', '+7-555-1009', '1990-02-14', 'F', '2016-08-20', 4500.00, 'CABIN_CREW', 1, TRUE, '30 Ataturk Blvd', 'Ivan Volkov +7-555-9009'),
('Amira', 'Hassan', 'a.hassan@skyport.com', '+20-555-1010', '1992-07-19', 'F', '2018-01-15', 4200.00, 'CABIN_CREW', 1, TRUE, '12 Nile St', 'Omar Hassan +20-555-9010'),
('Thomas', 'Fischer', 't.fischer@skyport.com', '+49-555-1011', '1988-10-03', 'M', '2014-05-01', 4800.00, 'CABIN_CREW', 2, TRUE, '7 Munich Lane', 'Anna Fischer +49-555-9011'),
('Charlotte', 'White', 'c.white@skyport.com', '+44-555-1012', '1993-12-08', 'F', '2019-03-10', 4000.00, 'CABIN_CREW', 3, TRUE, '44 Windsor Rd', 'James White +44-555-9012'),
('Pierre', 'Martin', 'p.martin@skyport.com', '+33-555-1013', '1991-04-22', 'M', '2017-09-01', 4300.00, 'CABIN_CREW', 4, TRUE, '16 Champs Ave', 'Louise Martin +33-555-9013'),
('Rashid', 'Omar', 'r.omar@skyport.com', '+971-555-1014', '1994-06-15', 'M', '2020-02-01', 5000.00, 'CABIN_CREW', 5, TRUE, 'Dubai Marina Apt', 'Fatima Omar +971-555-9014'),
('Sakura', 'Yamamoto', 's.yamamoto@skyport.com', '+81-555-1015', '1995-03-27', 'F', '2021-06-15', 4100.00, 'CABIN_CREW', 7, TRUE, '9-3 Shibuya', 'Ken Yamamoto +81-555-9015'),
('Jennifer', 'Clark', 'j.clark@skyport.com', '+1-555-1016', '1989-08-11', 'F', '2015-10-20', 4600.00, 'CABIN_CREW', 8, TRUE, '78 Peachtree St', 'Bob Clark +1-555-9016'),
-- Ground Staff (IDs 17-24)
('Mehmet', 'Kaya', 'm.kaya@skyport.com', '+90-555-1017', '1986-09-05', 'M', '2013-04-01', 3200.00, 'GROUND_STAFF', NULL, TRUE, '45 Airport Rd', 'Ayse Kaya +90-555-9017'),
('Carlos', 'Garcia', 'c.garcia@skyport.com', '+34-555-1018', '1991-01-20', 'M', '2017-07-15', 3000.00, 'GROUND_STAFF', NULL, TRUE, '20 Terminal Way', 'Maria Garcia +34-555-9018'),
('Linda', 'Nguyen', 'l.nguyen@skyport.com', '+84-555-1019', '1993-05-12', 'F', '2019-02-01', 2800.00, 'GROUND_STAFF', NULL, TRUE, '8 Skyport Ave', 'Tuan Nguyen +84-555-9019'),
('Patrick', 'OBrien', 'p.obrien@skyport.com', '+353-555-1020', '1987-11-28', 'M', '2014-08-10', 3100.00, 'GROUND_STAFF', NULL, TRUE, '33 Runway Close', 'Siobhan OBrien +353-555-9020'),
('Elif', 'Ozturk', 'e.ozturk@skyport.com', '+90-555-1021', '1994-03-16', 'F', '2020-06-01', 2900.00, 'GROUND_STAFF', NULL, TRUE, '67 Departure Rd', 'Murat Ozturk +90-555-9021'),
('Raj', 'Patel', 'r.patel@skyport.com', '+91-555-1022', '1989-07-04', 'M', '2016-01-15', 3300.00, 'GROUND_STAFF', NULL, TRUE, '11 Cargo Lane', 'Priya Patel +91-555-9022'),
('Olga', 'Ivanova', 'o.ivanova@skyport.com', '+7-555-1023', '1992-10-30', 'F', '2018-05-20', 2700.00, 'GROUND_STAFF', NULL, TRUE, '5 Check-in St', 'Dmitri Ivanov +7-555-9023'),
('Ahmed', 'Osman', 'a.osman@skyport.com', '+90-555-1024', '1985-12-18', 'M', '2011-03-01', 3500.00, 'GROUND_STAFF', NULL, TRUE, '88 Taxiway Rd', 'Hana Osman +90-555-9024'),
-- Security (IDs 25-30)
('John', 'Stone', 'j.stone@skyport.com', '+1-555-1025', '1983-04-09', 'M', '2010-09-01', 4000.00, 'SECURITY', NULL, TRUE, '15 Secure Lane', 'Emily Stone +1-555-9025'),
('Mustafa', 'Celik', 'm.celik@skyport.com', '+90-555-1026', '1987-08-22', 'M', '2014-12-15', 3800.00, 'SECURITY', NULL, TRUE, '22 Guard House', 'Zeynep Celik +90-555-9026'),
('Diana', 'Popescu', 'd.popescu@skyport.com', '+40-555-1027', '1990-06-03', 'F', '2017-04-01', 3500.00, 'SECURITY', NULL, TRUE, '9 Patrol Rd', 'Andrei Popescu +40-555-9027'),
('Viktor', 'Petrov', 'v.petrov@skyport.com', '+7-555-1028', '1984-11-14', 'M', '2012-07-20', 3900.00, 'SECURITY', NULL, TRUE, '4 Checkpoint Ave', 'Natalia Petrova +7-555-9028'),
('Fatih', 'Yildiz', 'f.yildiz@skyport.com', '+90-555-1029', '1988-02-27', 'M', '2015-10-01', 3600.00, 'SECURITY', NULL, TRUE, '18 Security Blvd', 'Selin Yildiz +90-555-9029'),
('Grace', 'Okonkwo', 'g.okonkwo@skyport.com', '+234-555-1030', '1991-09-15', 'F', '2019-01-10', 3400.00, 'SECURITY', NULL, TRUE, '7 Perimeter Dr', 'Daniel Okonkwo +234-555-9030');

-- ============================================================
-- PILOTS (details for 8 pilots)
-- ============================================================
INSERT INTO pilots (pilot_id, license_number, license_type, total_flight_hours, rating, medical_expiry, last_check_ride) VALUES
(1, 'ATPL-US-0001', 'ATPL', 18500.0, 'B737, B777, B787', '2027-03-15', '2026-01-20'),
(2, 'CPL-CN-0002', 'CPL', 8200.0, 'B737, A320', '2027-01-10', '2025-11-15'),
(3, 'ATPL-DE-0003', 'ATPL', 22000.0, 'A320, A330, A380', '2027-06-20', '2026-03-01'),
(4, 'ATPL-GB-0004', 'ATPL', 16500.0, 'B777, B787', '2027-04-30', '2026-02-10'),
(5, 'CPL-FR-0005', 'CPL', 6500.0, 'A320, A330', '2027-02-28', '2025-12-05'),
(6, 'ATPL-AE-0006', 'ATPL', 24000.0, 'A380, B777', '2027-08-15', '2026-04-20'),
(7, 'ATPL-JP-0007', 'ATPL', 20000.0, 'A380, B787', '2027-05-10', '2026-01-30'),
(8, 'CPL-US-0008', 'CPL', 5500.0, 'B737, B787', '2027-07-01', '2026-05-15');

-- ============================================================
-- CABIN CREW (details for 8)
-- ============================================================
INSERT INTO cabin_crew (crew_id, position, languages_spoken, certification_level, first_aid_certified) VALUES
(9, 'PURSER', 'English,Turkish,Russian', 'ADVANCED', TRUE),
(10, 'SENIOR_ATTENDANT', 'English,Arabic,Turkish', 'ADVANCED', TRUE),
(11, 'PURSER', 'English,German,French', 'INSTRUCTOR', TRUE),
(12, 'ATTENDANT', 'English,French', 'BASIC', TRUE),
(13, 'SENIOR_ATTENDANT', 'English,French,Italian', 'ADVANCED', TRUE),
(14, 'ATTENDANT', 'English,Arabic,Hindi', 'BASIC', TRUE),
(15, 'ATTENDANT', 'English,Japanese,Korean', 'BASIC', TRUE),
(16, 'SENIOR_ATTENDANT', 'English,Spanish', 'ADVANCED', TRUE);

-- ============================================================
-- GROUND STAFF (details for 8)
-- ============================================================
INSERT INTO ground_staff (staff_id, department, equipment_certified, shift_pattern, terminal_assigned) VALUES
(17, 'RAMP', 'Tug,Belt Loader,GPU', 'ROTATING', 1),
(18, 'CHECK_IN', 'Kiosk,Printer', 'MORNING', 2),
(19, 'CARGO', 'Forklift,Dolly,ULD Loader', 'AFTERNOON', NULL),
(20, 'CUSTOMER_SERVICE', 'Kiosk,Printer', 'ROTATING', 3),
(21, 'CHECK_IN', 'Kiosk,Printer,Scanner', 'MORNING', 1),
(22, 'CARGO', 'Forklift,Dolly,Pallet Jack', 'NIGHT', NULL),
(23, 'CUSTOMER_SERVICE', 'Kiosk', 'AFTERNOON', 4),
(24, 'OPERATIONS', 'Radio,GPU,Tug', 'ROTATING', NULL);

-- ============================================================
-- SECURITY PERSONNEL (details for 6)
-- ============================================================
INSERT INTO security_personnel (security_id, clearance_level, badge_number, assigned_zone, weapon_certified, last_training) VALUES
(25, 'TOP_SECRET', 'SEC-001', 'Terminal A - International', TRUE, '2026-05-01'),
(26, 'ELEVATED', 'SEC-002', 'Terminal B - Domestic', TRUE, '2026-04-15'),
(27, 'BASIC', 'SEC-003', 'Terminal C - Check-in Area', FALSE, '2026-03-20'),
(28, 'TOP_SECRET', 'SEC-004', 'Cargo & Restricted Zone', TRUE, '2026-05-10'),
(29, 'ELEVATED', 'SEC-005', 'Perimeter & Runways', TRUE, '2026-04-01'),
(30, 'BASIC', 'SEC-006', 'Terminal D - Arrivals', FALSE, '2026-06-01');

-- ============================================================
-- FLIGHT CREW ASSIGNMENTS (20 assignments)
-- ============================================================
INSERT INTO flight_crew_assignments (flight_id, employee_id, role) VALUES
(1, 1, 'CAPTAIN'), (1, 2, 'FIRST_OFFICER'), (1, 9, 'PURSER'), (1, 10, 'CABIN_CREW'),
(2, 1, 'CAPTAIN'), (2, 2, 'FIRST_OFFICER'), (2, 9, 'PURSER'),
(4, 3, 'CAPTAIN'), (4, 5, 'FIRST_OFFICER'), (4, 11, 'PURSER'),
(6, 4, 'CAPTAIN'), (6, 8, 'FIRST_OFFICER'), (6, 12, 'CABIN_CREW'),
(8, 5, 'CAPTAIN'), (8, 13, 'PURSER'),
(10, 6, 'CAPTAIN'), (10, 14, 'CABIN_CREW'),
(13, 7, 'CAPTAIN'), (13, 15, 'CABIN_CREW'),
(14, 8, 'CAPTAIN');

-- ============================================================
-- MAINTENANCE RECORDS (5 records)
-- ============================================================
INSERT INTO maintenance_records (aircraft_id, maintenance_type, description, start_date, end_date, performed_by, status, cost, parts_replaced, notes) VALUES
(4, 'ROUTINE', 'Regular A-check inspection including hydraulic system review', '2026-06-10 08:00:00', NULL, 24, 'IN_PROGRESS', 15000.00, 'Hydraulic filter, brake pads', 'Aircraft grounded for scheduled inspection'),
(8, 'REPAIR', 'APU starter motor replacement', '2026-06-08 14:00:00', '2026-06-09 18:00:00', 24, 'COMPLETED', 45000.00, 'APU starter motor, gaskets', 'Replacement completed successfully'),
(11, 'INSPECTION', 'Engine borescope inspection - both engines', '2026-06-12 06:00:00', '2026-06-12 14:00:00', 22, 'COMPLETED', 8000.00, NULL, 'No issues found'),
(16, 'EMERGENCY', 'Bird strike damage assessment and nose cone repair', '2026-06-12 20:00:00', NULL, 24, 'IN_PROGRESS', 120000.00, 'Radome, pitot tube cover', 'Aircraft grounded pending FAA inspection'),
(5, 'OVERHAUL', 'Landing gear overhaul - main and nose gear', '2026-06-01 08:00:00', '2026-06-05 16:00:00', 22, 'COMPLETED', 250000.00, 'Tires, brake assemblies, actuators, seals', 'Major overhaul completed within schedule');

-- ============================================================
-- PARKING LOTS (4 lots)
-- ============================================================
INSERT INTO parking_lots (lot_name, lot_type, total_spots, available_spots, hourly_rate, daily_max, terminal_id, is_covered) VALUES
('P1 Short-Term', 'SHORT_TERM', 500, 320, 5.00, 40.00, 1, TRUE),
('P2 Long-Term', 'LONG_TERM', 2000, 1450, 2.50, 18.00, 2, FALSE),
('P3 VIP Parking', 'VIP', 100, 72, 12.00, 80.00, 1, TRUE),
('P4 Employee', 'EMPLOYEE', 300, 180, 0.00, 0.00, NULL, FALSE);

-- ============================================================
-- PARKING RESERVATIONS (6 reservations)
-- ============================================================
INSERT INTO parking_reservations (lot_id, passenger_id, license_plate, entry_time, exit_time, total_charge, status) VALUES
(1, 1, '34 ABC 123', '2026-06-14 05:30:00', NULL, 0.00, 'ACTIVE'),
(1, 3, '06 DEF 456', '2026-06-14 06:00:00', NULL, 0.00, 'ACTIVE'),
(3, 5, 'DXB 9999', '2026-06-14 19:00:00', NULL, 0.00, 'ACTIVE'),
(2, 13, 'NSW 1234', '2026-06-12 08:00:00', NULL, 0.00, 'ACTIVE'),
(2, 15, 'STHLM 567', '2026-06-13 14:00:00', NULL, 0.00, 'ACTIVE'),
(1, 19, '34 GHI 789', '2026-06-14 05:45:00', '2026-06-14 14:00:00', 40.00, 'COMPLETED');

-- ============================================================
-- SHOPS (8 shops)
-- ============================================================
INSERT INTO shops (shop_name, shop_type, terminal_id, floor_number, opening_time, closing_time, is_active, monthly_rent) VALUES
('World Duty Free', 'DUTY_FREE', 1, 2, '05:00:00', '23:00:00', TRUE, 25000.00),
('Sky Bistro', 'RESTAURANT', 1, 2, '06:00:00', '22:00:00', TRUE, 15000.00),
('Cloud Nine Lounge', 'LOUNGE', 1, 3, '00:00:00', '23:59:59', TRUE, 20000.00),
('TechFly Electronics', 'ELECTRONICS', 2, 1, '07:00:00', '21:00:00', TRUE, 12000.00),
('Airport Bookworm', 'BOOKSTORE', 2, 1, '06:00:00', '22:00:00', TRUE, 8000.00),
('Espresso Terminal', 'CAFE', 3, 1, '05:00:00', '23:00:00', TRUE, 10000.00),
('Runway Fashion', 'FASHION', 3, 2, '08:00:00', '20:00:00', TRUE, 18000.00),
('SkyHealth Pharmacy', 'PHARMACY', 4, 1, '06:00:00', '22:00:00', TRUE, 9000.00);

-- ============================================================
-- SHOP TRANSACTIONS (12 transactions)
-- ============================================================
INSERT INTO shop_transactions (shop_id, passenger_id, amount, payment_method, items_purchased) VALUES
(1, 1, 185.00, 'CREDIT_CARD', 'Whiskey (1L), Chocolate box, Perfume sample'),
(1, 5, 520.00, 'CREDIT_CARD', 'Designer sunglasses, Premium cognac'),
(2, 3, 45.00, 'CASH', 'Grilled chicken meal, sparkling water'),
(2, 4, 62.00, 'DEBIT_CARD', 'Steak dinner, glass of wine'),
(3, 5, 75.00, 'MILES', 'Lounge access pass'),
(4, 7, 299.00, 'CREDIT_CARD', 'Noise-cancelling headphones'),
(5, 6, 32.00, 'CASH', 'Novel, travel magazine, crossword book'),
(6, 2, 8.50, 'DEBIT_CARD', 'Double espresso, croissant'),
(6, 10, 12.00, 'CASH', 'Latte, blueberry muffin'),
(7, 12, 450.00, 'CREDIT_CARD', 'Cashmere scarf, leather wallet'),
(8, 14, 28.00, 'DEBIT_CARD', 'Travel toiletry kit, pain relievers'),
(1, 25, 340.00, 'CREDIT_CARD', 'Premium chocolate collection, wine set');

-- ============================================================
-- FLIGHT STATUS HISTORY (seeded for already-changed flights)
-- ============================================================
INSERT INTO flight_status_history (flight_id, old_status, new_status, changed_at, changed_by, notes) VALUES
(6, 'SCHEDULED', 'DELAYED', '2026-06-14 10:15:00', 'SYSTEM', 'Delayed by 45 minutes. Reason: Weather conditions'),
(8, 'SCHEDULED', 'BOARDING', '2026-06-14 05:45:00', 'SYSTEM', 'Status changed from SCHEDULED to BOARDING'),
(8, 'BOARDING', 'DEPARTED', '2026-06-14 06:30:00', 'SYSTEM', 'Status changed from BOARDING to DEPARTED'),
(8, 'DEPARTED', 'ARRIVED', '2026-06-14 09:05:00', 'SYSTEM', 'Status changed from DEPARTED to ARRIVED'),
(11, 'SCHEDULED', 'BOARDING', '2026-06-14 09:15:00', 'SYSTEM', 'Status changed from SCHEDULED to BOARDING'),
(11, 'BOARDING', 'DEPARTED', '2026-06-14 10:00:00', 'SYSTEM', 'Status changed from BOARDING to DEPARTED'),
(11, 'DEPARTED', 'IN_AIR', '2026-06-14 10:30:00', 'SYSTEM', 'Status changed from DEPARTED to IN_AIR'),
(12, 'SCHEDULED', 'BOARDING', '2026-06-14 00:45:00', 'SYSTEM', 'Status changed from SCHEDULED to BOARDING'),
(12, 'BOARDING', 'DEPARTED', '2026-06-14 01:30:00', 'SYSTEM', 'Status changed from BOARDING to DEPARTED'),
(12, 'DEPARTED', 'ARRIVED', '2026-06-14 07:05:00', 'SYSTEM', 'Status changed from DEPARTED to ARRIVED'),
(20, 'SCHEDULED', 'CANCELLED', '2026-06-14 14:00:00', 'SYSTEM', 'Flight cancelled. Reason: Technical issue');

-- ============================================================
-- AUDIT LOG (sample entries)
-- ============================================================
INSERT INTO audit_log (table_name, operation, record_id, new_values, performed_by, performed_at) VALUES
('flights', 'UPDATE', 6, '{"status": "DELAYED", "delay_minutes": 45}', 'SYSTEM', '2026-06-14 10:15:00'),
('flights', 'UPDATE', 20, '{"status": "CANCELLED"}', 'SYSTEM', '2026-06-14 14:00:00'),
('maintenance_records', 'INSERT', 1, '{"aircraft": "TC-JOE", "type": "ROUTINE"}', 'Ahmed Osman', '2026-06-10 08:00:00'),
('maintenance_records', 'INSERT', 4, '{"aircraft": "N802DN", "type": "EMERGENCY"}', 'Ahmed Osman', '2026-06-12 20:00:00');
