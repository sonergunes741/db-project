-- ============================================================
-- SKYPORT INTERNATIONAL AIRPORT DATABASE
-- 06_transactions.sql — Atomic Transactions (4)
-- ============================================================

USE skyport_airport;

-- ============================================================
-- TRANSACTION 1: Complete Flight Booking
-- Books a seat, creates booking, generates boarding pass, awards miles
-- Demonstrates ATOMICITY: all steps succeed or all roll back
-- ============================================================

-- Example: Passenger 9 (Chen Wei) books Economy on flight TK1
DELIMITER //
DROP PROCEDURE IF EXISTS demo_transaction_booking//
CREATE PROCEDURE demo_transaction_booking()
BEGIN
    DECLARE v_booking_id INT;
    DECLARE v_result VARCHAR(200);
    
    -- Show state BEFORE
    SELECT 'BEFORE BOOKING' AS phase, available_seats FROM flights WHERE flight_id = 1;
    
    -- Execute atomic booking
    CALL sp_book_flight(9, 1, 'ECONOMY', '26E', @book_id, @book_result);
    
    SELECT @book_result AS booking_result;
    
    -- Show state AFTER
    SELECT 'AFTER BOOKING' AS phase, available_seats FROM flights WHERE flight_id = 1;
    SELECT * FROM bookings WHERE booking_id = @book_id;
    SELECT * FROM boarding_passes WHERE booking_id = @book_id;
END//
DELIMITER ;

-- ============================================================
-- TRANSACTION 2: Flight Cancellation with Refund
-- Cancels booking, releases seat, processes refund, adjusts miles
-- ============================================================

DELIMITER //
DROP PROCEDURE IF EXISTS demo_transaction_cancellation//
CREATE PROCEDURE demo_transaction_cancellation()
BEGIN
    -- Show state BEFORE
    SELECT 'BEFORE CANCELLATION' AS phase, 
           booking_status, payment_status, price 
    FROM bookings WHERE booking_id = 8;
    
    SELECT available_seats FROM flights WHERE flight_id = 2;
    
    -- Execute atomic cancellation
    CALL sp_cancel_booking(8, @cancel_result);
    
    SELECT @cancel_result AS cancellation_result;
    
    -- Show state AFTER
    SELECT 'AFTER CANCELLATION' AS phase,
           booking_status, payment_status, price 
    FROM bookings WHERE booking_id = 8;
    
    SELECT available_seats FROM flights WHERE flight_id = 2;
END//
DELIMITER ;

-- ============================================================
-- TRANSACTION 3: Gate Reassignment
-- Releases old gate, assigns new gate atomically
-- ============================================================

DELIMITER //
DROP PROCEDURE IF EXISTS demo_transaction_gate_reassign//
CREATE PROCEDURE demo_transaction_gate_reassign()
BEGIN
    -- Show current assignment
    SELECT 'BEFORE REASSIGNMENT' AS phase, 
           ga.*, g.gate_number 
    FROM gate_assignments ga
    JOIN gates g ON ga.gate_id = g.gate_id
    WHERE ga.flight_id = 1 AND ga.status = 'ACTIVE';
    
    -- Reassign flight 1 from gate 1 (A1) to gate 5 (A5)
    CALL sp_reassign_gate(1, 5, @gate_result);
    
    SELECT @gate_result AS reassignment_result;
    
    -- Show new assignment
    SELECT 'AFTER REASSIGNMENT' AS phase,
           ga.*, g.gate_number 
    FROM gate_assignments ga
    JOIN gates g ON ga.gate_id = g.gate_id
    WHERE ga.flight_id = 1
    ORDER BY ga.assignment_id DESC;
END//
DELIMITER ;

-- ============================================================
-- TRANSACTION 4: Passenger Transfer Between Flights
-- Cancel old booking, create new booking, transfer baggage — all atomic
-- ============================================================

DELIMITER //
DROP PROCEDURE IF EXISTS demo_transaction_transfer//
CREATE PROCEDURE demo_transaction_transfer()
BEGIN
    -- Show state BEFORE
    SELECT 'BEFORE TRANSFER' AS phase;
    SELECT b.booking_id, b.booking_ref, b.flight_id, f.flight_number, b.booking_status
    FROM bookings b JOIN flights f ON b.flight_id = f.flight_id
    WHERE b.booking_id = 13;
    
    SELECT baggage_id, tag_number, booking_id FROM baggage WHERE booking_id = 13;
    
    -- Transfer passenger from flight 6 (BA300) to flight 18 (BA302)
    CALL sp_transfer_passenger(13, 18, '15A', @transfer_result);
    
    SELECT @transfer_result AS transfer_result;
    
    -- Show state AFTER
    SELECT 'AFTER TRANSFER' AS phase;
    SELECT b.booking_id, b.booking_ref, b.flight_id, f.flight_number, b.booking_status
    FROM bookings b JOIN flights f ON b.flight_id = f.flight_id
    WHERE b.passenger_id = 13
    ORDER BY b.booking_id DESC;
END//
DELIMITER ;

-- ============================================================
-- TRANSACTION FAILURE DEMO: Shows rollback on error
-- Attempts to book when no seats available
-- ============================================================

DELIMITER //
DROP PROCEDURE IF EXISTS demo_transaction_failure//
CREATE PROCEDURE demo_transaction_failure()
BEGIN
    DECLARE v_flight_id INT DEFAULT 20;  -- Cancelled flight
    
    SELECT 'ATTEMPTING TO BOOK CANCELLED FLIGHT' AS phase;
    SELECT flight_number, status, available_seats FROM flights WHERE flight_id = v_flight_id;
    
    -- This should fail gracefully and rollback
    CALL sp_book_flight(1, v_flight_id, 'ECONOMY', '10A', @fail_id, @fail_result);
    
    SELECT @fail_result AS result;
    SELECT 'Transaction was rolled back - no data was modified' AS explanation;
END//
DELIMITER ;
