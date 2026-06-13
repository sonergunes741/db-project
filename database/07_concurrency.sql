-- ============================================================
-- SKYPORT INTERNATIONAL AIRPORT DATABASE
-- 07_concurrency.sql — Concurrency Control (3 examples)
-- ============================================================

USE skyport_airport;

-- ============================================================
-- CONCURRENCY EXAMPLE 1: Preventing Double Seat Booking
-- Uses SELECT ... FOR UPDATE (Pessimistic Locking)
-- 
-- Scenario: Two passengers try to book the last seat on the same flight
-- Without locking, both could succeed → overbooking!
-- ============================================================

DELIMITER //

DROP PROCEDURE IF EXISTS demo_concurrent_booking_session1//
CREATE PROCEDURE demo_concurrent_booking_session1()
BEGIN
    DECLARE v_available INT;
    
    -- SESSION 1: Start transaction and acquire lock
    START TRANSACTION;
    
    SELECT '--- SESSION 1: Acquiring lock on flight row ---' AS step;
    
    -- FOR UPDATE locks the row - no other transaction can modify it
    SELECT available_seats INTO v_available 
    FROM flights 
    WHERE flight_id = 7  -- BA301 
    FOR UPDATE;
    
    SELECT CONCAT('Available seats (locked): ', v_available) AS session1_info;
    
    IF v_available > 0 THEN
        -- Book the seat
        UPDATE flights SET available_seats = available_seats - 1 WHERE flight_id = 7;
        
        INSERT INTO bookings (booking_ref, passenger_id, flight_id, booking_class, seat_number, price, booking_status, payment_status)
        VALUES (UPPER(SUBSTRING(MD5(RAND()), 1, 6)), 16, 7, 'ECONOMY', '35A', 350.00, 'CONFIRMED', 'PAID');
        
        SELECT 'SESSION 1: Booking successful!' AS result;
        COMMIT;
    ELSE
        SELECT 'SESSION 1: No seats available!' AS result;
        ROLLBACK;
    END IF;
    
    -- At this point, the lock is released and Session 2 can proceed
    -- Session 2 would see the UPDATED available_seats count
END//

-- What Session 2 would do (in a separate connection):
-- It would block on SELECT ... FOR UPDATE until Session 1 commits/rollbacks
-- Then it sees the correct available_seats value

DROP PROCEDURE IF EXISTS demo_concurrent_booking_session2//
CREATE PROCEDURE demo_concurrent_booking_session2()
BEGIN
    DECLARE v_available INT;
    
    START TRANSACTION;
    
    SELECT '--- SESSION 2: Waiting for lock (would block if Session 1 active) ---' AS step;
    
    -- This SELECT would BLOCK until Session 1 releases the lock
    SELECT available_seats INTO v_available 
    FROM flights 
    WHERE flight_id = 7 
    FOR UPDATE;
    
    SELECT CONCAT('Available seats after Session 1: ', v_available) AS session2_info;
    
    IF v_available > 0 THEN
        UPDATE flights SET available_seats = available_seats - 1 WHERE flight_id = 7;
        
        INSERT INTO bookings (booking_ref, passenger_id, flight_id, booking_class, seat_number, price, booking_status, payment_status)
        VALUES (UPPER(SUBSTRING(MD5(RAND()), 1, 6)), 20, 7, 'ECONOMY', '35B', 350.00, 'CONFIRMED', 'PAID');
        
        SELECT 'SESSION 2: Booking successful!' AS result;
        COMMIT;
    ELSE
        SELECT 'SESSION 2: No seats - prevented overbooking!' AS result;
        ROLLBACK;
    END IF;
END//

DELIMITER ;

-- ============================================================
-- CONCURRENCY EXAMPLE 2: Gate Assignment Conflict Prevention
-- Uses Row-Level Locking
--
-- Scenario: Two flights try to be assigned to the same gate
-- at overlapping times
-- ============================================================

DELIMITER //

DROP PROCEDURE IF EXISTS demo_concurrent_gate_assignment//
CREATE PROCEDURE demo_concurrent_gate_assignment()
BEGIN
    DECLARE v_conflict_count INT;
    DECLARE v_gate INT DEFAULT 9; -- Gate B4
    
    -- Transaction A: Try to assign gate B4 to flight 5
    START TRANSACTION;
    
    SELECT '--- Checking gate B4 for conflicts (with lock) ---' AS step;
    
    -- Lock the gate row
    SELECT gate_id FROM gates WHERE gate_id = v_gate FOR UPDATE;
    
    -- Check for time conflicts
    SELECT COUNT(*) INTO v_conflict_count
    FROM gate_assignments
    WHERE gate_id = v_gate
      AND status = 'ACTIVE'
      AND (('2026-06-14 14:30:00' BETWEEN start_time AND end_time)
           OR ('2026-06-14 16:30:00' BETWEEN start_time AND end_time));
    
    IF v_conflict_count = 0 THEN
        INSERT INTO gate_assignments (flight_id, gate_id, start_time, end_time, status)
        VALUES (5, v_gate, '2026-06-14 14:30:00', '2026-06-14 16:30:00', 'ACTIVE');
        
        SELECT 'Gate B4 assigned to LH401 successfully' AS result;
        COMMIT;
    ELSE
        SELECT 'Gate B4 has a conflict - cannot assign!' AS result;
        ROLLBACK;
    END IF;
    
    -- Show final state
    SELECT ga.*, g.gate_number, f.flight_number 
    FROM gate_assignments ga
    JOIN gates g ON ga.gate_id = g.gate_id
    JOIN flights f ON ga.flight_id = f.flight_id
    WHERE ga.gate_id = v_gate;
END//

DELIMITER ;

-- ============================================================
-- CONCURRENCY EXAMPLE 3: Parking Spot Reservation
-- Uses Optimistic Locking with Version Check
--
-- Scenario: Two passengers try to reserve the last VIP parking spot
-- Uses available_spots as a "version" field
-- ============================================================

DELIMITER //

DROP PROCEDURE IF EXISTS demo_concurrent_parking//
CREATE PROCEDURE demo_concurrent_parking()
BEGIN
    DECLARE v_spots_before INT;
    DECLARE v_rows_affected INT;
    
    -- Read current available spots (no lock = optimistic approach)
    SELECT available_spots INTO v_spots_before
    FROM parking_lots WHERE lot_id = 3;  -- VIP Parking
    
    SELECT CONCAT('VIP Parking spots available: ', v_spots_before) AS initial_state;
    
    -- SESSION A: Try to reserve with optimistic locking
    START TRANSACTION;
    
    -- The WHERE clause includes the expected available_spots value
    -- If another session changed it, this UPDATE will affect 0 rows
    UPDATE parking_lots 
    SET available_spots = available_spots - 1
    WHERE lot_id = 3 
      AND available_spots = v_spots_before  -- Optimistic lock check
      AND available_spots > 0;
    
    SET v_rows_affected = ROW_COUNT();
    
    IF v_rows_affected > 0 THEN
        INSERT INTO parking_reservations (lot_id, passenger_id, license_plate, entry_time, status)
        VALUES (3, 22, 'MUC 4567', NOW(), 'ACTIVE');
        
        SELECT 'SESSION A: VIP parking reserved successfully!' AS result;
        COMMIT;
    ELSE
        SELECT 'SESSION A: Spots changed by another session - retry needed!' AS result;
        ROLLBACK;
    END IF;
    
    -- Show final state
    SELECT lot_name, available_spots, total_spots FROM parking_lots WHERE lot_id = 3;
    
    -- Demonstrate what would happen if Session B tried simultaneously:
    SELECT '--- If Session B tried with stale data ---' AS note;
    SELECT 'Session B would read available_spots as the OLD value' AS explanation;
    SELECT 'The UPDATE WHERE available_spots = <old_value> would match 0 rows' AS explanation2;
    SELECT 'Session B knows to RETRY with fresh data (optimistic locking pattern)' AS explanation3;
END//

DELIMITER ;

-- ============================================================
-- ISOLATION LEVEL DEMONSTRATION
-- Shows how different isolation levels affect concurrent reads
-- ============================================================

DELIMITER //

DROP PROCEDURE IF EXISTS demo_isolation_levels//
CREATE PROCEDURE demo_isolation_levels()
BEGIN
    SELECT '=== ISOLATION LEVEL COMPARISON ===' AS header;
    
    -- Show current isolation level
    SELECT @@transaction_isolation AS current_isolation_level;
    
    -- READ UNCOMMITTED: Can see uncommitted changes (dirty reads)
    SELECT 'READ UNCOMMITTED: Allows dirty reads - other transactions can see your uncommitted changes' AS level_1;
    
    -- READ COMMITTED: Only sees committed data
    SELECT 'READ COMMITTED: Only sees committed data - no dirty reads, but non-repeatable reads possible' AS level_2;
    
    -- REPEATABLE READ (MySQL default): Consistent reads within transaction
    SELECT 'REPEATABLE READ (MySQL default): Guarantees same results for repeated reads within a transaction' AS level_3;
    
    -- SERIALIZABLE: Full isolation
    SELECT 'SERIALIZABLE: Full isolation - transactions execute as if serial, highest consistency, lowest concurrency' AS level_4;
    
    -- Demonstrate setting isolation level
    SELECT 'To change: SET TRANSACTION ISOLATION LEVEL READ COMMITTED;' AS how_to_change;
END//

DELIMITER ;
