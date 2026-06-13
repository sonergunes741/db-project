-- ============================================================
-- SKYPORT INTERNATIONAL AIRPORT DATABASE
-- 03_functions_procedures.sql — Functions & Stored Procedures (12)
-- ============================================================

USE skyport_airport;

DELIMITER //

-- ============================================================
-- FUNCTION 1: Calculate flight duration in minutes
-- ============================================================
DROP FUNCTION IF EXISTS fn_calculate_flight_duration//
CREATE FUNCTION fn_calculate_flight_duration(p_flight_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_duration INT;
    
    SELECT TIMESTAMPDIFF(MINUTE, 
        COALESCE(actual_departure, scheduled_departure),
        COALESCE(actual_arrival, scheduled_arrival))
    INTO v_duration
    FROM flights
    WHERE flight_id = p_flight_id;
    
    RETURN COALESCE(v_duration, 0);
END//

-- ============================================================
-- FUNCTION 2: Get total miles for a passenger
-- ============================================================
DROP FUNCTION IF EXISTS fn_get_passenger_miles//
CREATE FUNCTION fn_get_passenger_miles(p_passenger_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_miles INT DEFAULT 0;
    
    SELECT COALESCE(total_miles, 0) INTO v_miles
    FROM frequent_flyer
    WHERE passenger_id = p_passenger_id;
    
    RETURN v_miles;
END//

-- ============================================================
-- FUNCTION 3: Aircraft utilization rate (percentage)
-- ============================================================
DROP FUNCTION IF EXISTS fn_aircraft_utilization_rate//
CREATE FUNCTION fn_aircraft_utilization_rate(p_aircraft_id INT, p_days INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_flight_hours DECIMAL(10,2);
    DECLARE v_total_hours DECIMAL(10,2);
    
    SET v_total_hours = p_days * 24;
    
    SELECT COALESCE(SUM(TIMESTAMPDIFF(HOUR,
        COALESCE(actual_departure, scheduled_departure),
        COALESCE(actual_arrival, scheduled_arrival))), 0)
    INTO v_flight_hours
    FROM flights
    WHERE aircraft_id = p_aircraft_id
      AND scheduled_departure >= DATE_SUB(NOW(), INTERVAL p_days DAY)
      AND status NOT IN ('CANCELLED');
    
    IF v_total_hours = 0 THEN RETURN 0; END IF;
    
    RETURN ROUND((v_flight_hours / v_total_hours) * 100, 2);
END//

-- ============================================================
-- FUNCTION 4: Gate occupancy rate
-- ============================================================
DROP FUNCTION IF EXISTS fn_gate_occupancy_rate//
CREATE FUNCTION fn_gate_occupancy_rate(p_gate_id INT, p_date DATE)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_occupied_hours DECIMAL(10,2);
    
    SELECT COALESCE(SUM(TIMESTAMPDIFF(MINUTE, start_time, end_time) / 60.0), 0)
    INTO v_occupied_hours
    FROM gate_assignments
    WHERE gate_id = p_gate_id
      AND DATE(start_time) = p_date
      AND status = 'ACTIVE';
    
    RETURN ROUND((v_occupied_hours / 24) * 100, 2);
END//

-- ============================================================
-- FUNCTION 5: Flight occupancy (% seats booked)
-- ============================================================
DROP FUNCTION IF EXISTS fn_flight_occupancy//
CREATE FUNCTION fn_flight_occupancy(p_flight_id INT)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_total INT;
    DECLARE v_available INT;
    
    SELECT total_seats, available_seats 
    INTO v_total, v_available
    FROM flights
    WHERE flight_id = p_flight_id;
    
    IF v_total = 0 OR v_total IS NULL THEN RETURN 0; END IF;
    
    RETURN ROUND(((v_total - v_available) / v_total) * 100, 2);
END//

-- ============================================================
-- FUNCTION 6: Get airline revenue for date range
-- ============================================================
DROP FUNCTION IF EXISTS fn_get_airline_revenue//
CREATE FUNCTION fn_get_airline_revenue(p_airline_id INT, p_start DATE, p_end DATE)
RETURNS DECIMAL(12,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_revenue DECIMAL(12,2);
    
    SELECT COALESCE(SUM(b.price), 0) INTO v_revenue
    FROM bookings b
    JOIN flights f ON b.flight_id = f.flight_id
    WHERE f.airline_id = p_airline_id
      AND b.booking_date BETWEEN p_start AND p_end
      AND b.booking_status != 'CANCELLED'
      AND b.payment_status = 'PAID';
    
    RETURN v_revenue;
END//

-- ============================================================
-- STORED PROCEDURE 1: Book a flight (transactional)
-- ============================================================
DROP PROCEDURE IF EXISTS sp_book_flight//
CREATE PROCEDURE sp_book_flight(
    IN p_passenger_id INT,
    IN p_flight_id INT,
    IN p_class ENUM('ECONOMY','PREMIUM_ECONOMY','BUSINESS','FIRST'),
    IN p_seat VARCHAR(4),
    OUT p_booking_id INT,
    OUT p_result VARCHAR(200)
)
BEGIN
    DECLARE v_available INT;
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_ref VARCHAR(6);
    DECLARE v_class_multiplier DECIMAL(3,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Transaction rolled back due to an error';
        SET p_booking_id = NULL;
    END;
    
    START TRANSACTION;
    
    -- Lock the flight row to prevent race conditions
    SELECT available_seats, base_price 
    INTO v_available, v_price
    FROM flights 
    WHERE flight_id = p_flight_id
    FOR UPDATE;
    
    IF v_available IS NULL THEN
        ROLLBACK;
        SET p_result = 'ERROR: Flight not found';
        SET p_booking_id = NULL;
    ELSEIF v_available <= 0 THEN
        ROLLBACK;
        SET p_result = 'ERROR: No seats available';
        SET p_booking_id = NULL;
    ELSE
        -- Calculate price based on class
        SET v_class_multiplier = CASE p_class
            WHEN 'ECONOMY' THEN 1.00
            WHEN 'PREMIUM_ECONOMY' THEN 1.50
            WHEN 'BUSINESS' THEN 2.50
            WHEN 'FIRST' THEN 4.00
        END;
        SET v_price = v_price * v_class_multiplier;
        
        -- Generate booking reference
        SET v_ref = UPPER(SUBSTRING(MD5(CONCAT(p_passenger_id, p_flight_id, NOW())), 1, 6));
        
        -- Create booking
        INSERT INTO bookings (booking_ref, passenger_id, flight_id, booking_class, seat_number, price, booking_status, payment_status)
        VALUES (v_ref, p_passenger_id, p_flight_id, p_class, p_seat, v_price, 'CONFIRMED', 'PAID');
        
        SET p_booking_id = LAST_INSERT_ID();
        
        -- Update available seats
        UPDATE flights 
        SET available_seats = available_seats - 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE flight_id = p_flight_id;
        
        -- Award frequent flyer miles (distance-based approximation)
        UPDATE frequent_flyer 
        SET total_miles = total_miles + FLOOR(v_price),
            available_miles = available_miles + FLOOR(v_price),
            last_activity = CURDATE()
        WHERE passenger_id = p_passenger_id;
        
        COMMIT;
        SET p_result = CONCAT('SUCCESS: Booking ', v_ref, ' created. Price: $', v_price);
    END IF;
END//

-- ============================================================
-- STORED PROCEDURE 2: Cancel a booking
-- ============================================================
DROP PROCEDURE IF EXISTS sp_cancel_booking//
CREATE PROCEDURE sp_cancel_booking(
    IN p_booking_id INT,
    OUT p_result VARCHAR(200)
)
BEGIN
    DECLARE v_flight_id INT;
    DECLARE v_status VARCHAR(20);
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_passenger_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Transaction rolled back';
    END;
    
    START TRANSACTION;
    
    SELECT flight_id, booking_status, price, passenger_id
    INTO v_flight_id, v_status, v_price, v_passenger_id
    FROM bookings
    WHERE booking_id = p_booking_id
    FOR UPDATE;
    
    IF v_status IS NULL THEN
        ROLLBACK;
        SET p_result = 'ERROR: Booking not found';
    ELSEIF v_status = 'CANCELLED' THEN
        ROLLBACK;
        SET p_result = 'ERROR: Booking already cancelled';
    ELSE
        -- Cancel the booking
        UPDATE bookings 
        SET booking_status = 'CANCELLED',
            payment_status = 'REFUNDED',
            updated_at = CURRENT_TIMESTAMP
        WHERE booking_id = p_booking_id;
        
        -- Release the seat
        UPDATE flights 
        SET available_seats = available_seats + 1,
            updated_at = CURRENT_TIMESTAMP
        WHERE flight_id = v_flight_id;
        
        -- Deduct miles that were awarded
        UPDATE frequent_flyer 
        SET total_miles = GREATEST(0, total_miles - FLOOR(v_price)),
            available_miles = GREATEST(0, available_miles - FLOOR(v_price))
        WHERE passenger_id = v_passenger_id;
        
        COMMIT;
        SET p_result = CONCAT('SUCCESS: Booking cancelled. Refund: $', v_price);
    END IF;
END//

-- ============================================================
-- STORED PROCEDURE 3: Reassign a gate
-- ============================================================
DROP PROCEDURE IF EXISTS sp_reassign_gate//
CREATE PROCEDURE sp_reassign_gate(
    IN p_flight_id INT,
    IN p_new_gate_id INT,
    OUT p_result VARCHAR(200)
)
BEGIN
    DECLARE v_old_gate INT;
    DECLARE v_old_assignment INT;
    DECLARE v_start DATETIME;
    DECLARE v_end DATETIME;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Gate reassignment failed';
    END;
    
    START TRANSACTION;
    
    -- Find current gate assignment
    SELECT assignment_id, gate_id, start_time, end_time
    INTO v_old_assignment, v_old_gate, v_start, v_end
    FROM gate_assignments
    WHERE flight_id = p_flight_id AND status = 'ACTIVE'
    ORDER BY assignment_id DESC
    LIMIT 1
    FOR UPDATE;
    
    IF v_old_assignment IS NULL THEN
        ROLLBACK;
        SET p_result = 'ERROR: No active gate assignment found for this flight';
    ELSE
        -- Cancel old assignment
        UPDATE gate_assignments SET status = 'CANCELLED' WHERE assignment_id = v_old_assignment;
        UPDATE gates SET is_available = TRUE WHERE gate_id = v_old_gate;
        
        -- Create new assignment (trigger will check availability)
        INSERT INTO gate_assignments (flight_id, gate_id, start_time, end_time)
        VALUES (p_flight_id, p_new_gate_id, v_start, v_end);
        
        COMMIT;
        SET p_result = CONCAT('SUCCESS: Flight reassigned from gate ', v_old_gate, ' to gate ', p_new_gate_id);
    END IF;
END//

-- ============================================================
-- STORED PROCEDURE 4: Generate daily report
-- ============================================================
DROP PROCEDURE IF EXISTS sp_generate_daily_report//
CREATE PROCEDURE sp_generate_daily_report(
    IN p_date DATE
)
BEGIN
    -- Flight summary
    SELECT 
        'FLIGHT SUMMARY' as report_section,
        COUNT(*) as total_flights,
        SUM(CASE WHEN status = 'ARRIVED' THEN 1 ELSE 0 END) as completed,
        SUM(CASE WHEN status = 'DELAYED' THEN 1 ELSE 0 END) as delayed,
        SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END) as cancelled,
        ROUND(AVG(delay_minutes), 1) as avg_delay_min
    FROM flights
    WHERE DATE(scheduled_departure) = p_date;
    
    -- Passenger summary
    SELECT 
        'PASSENGER SUMMARY' as report_section,
        COUNT(DISTINCT b.passenger_id) as total_passengers,
        SUM(CASE WHEN b.booking_status = 'CHECKED_IN' THEN 1 ELSE 0 END) as checked_in,
        SUM(CASE WHEN b.booking_status = 'NO_SHOW' THEN 1 ELSE 0 END) as no_shows,
        SUM(b.price) as total_revenue
    FROM bookings b
    JOIN flights f ON b.flight_id = f.flight_id
    WHERE DATE(f.scheduled_departure) = p_date;
    
    -- Baggage summary
    SELECT 
        'BAGGAGE SUMMARY' as report_section,
        COUNT(*) as total_baggage,
        SUM(CASE WHEN status = 'LOST' THEN 1 ELSE 0 END) as lost,
        SUM(CASE WHEN status = 'DAMAGED' THEN 1 ELSE 0 END) as damaged,
        ROUND(AVG(weight_kg), 2) as avg_weight
    FROM baggage bg
    JOIN bookings b ON bg.booking_id = b.booking_id
    JOIN flights f ON b.flight_id = f.flight_id
    WHERE DATE(f.scheduled_departure) = p_date;
END//

-- ============================================================
-- STORED PROCEDURE 5: Check-in passenger
-- ============================================================
DROP PROCEDURE IF EXISTS sp_check_in_passenger//
CREATE PROCEDURE sp_check_in_passenger(
    IN p_booking_id INT,
    IN p_seat VARCHAR(4),
    OUT p_result VARCHAR(200)
)
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_flight_status VARCHAR(20);
    DECLARE v_flight_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Check-in failed';
    END;
    
    START TRANSACTION;
    
    SELECT b.booking_status, b.flight_id, f.status
    INTO v_status, v_flight_id, v_flight_status
    FROM bookings b
    JOIN flights f ON b.flight_id = f.flight_id
    WHERE b.booking_id = p_booking_id
    FOR UPDATE;
    
    IF v_status IS NULL THEN
        ROLLBACK;
        SET p_result = 'ERROR: Booking not found';
    ELSEIF v_status != 'CONFIRMED' THEN
        ROLLBACK;
        SET p_result = CONCAT('ERROR: Cannot check in. Current status: ', v_status);
    ELSEIF v_flight_status = 'CANCELLED' THEN
        ROLLBACK;
        SET p_result = 'ERROR: Flight has been cancelled';
    ELSE
        UPDATE bookings 
        SET booking_status = 'CHECKED_IN',
            seat_number = COALESCE(p_seat, seat_number),
            updated_at = CURRENT_TIMESTAMP
        WHERE booking_id = p_booking_id;
        
        -- Update boarding pass with gate info
        UPDATE boarding_passes bp
        JOIN gate_assignments ga ON ga.flight_id = v_flight_id AND ga.status = 'ACTIVE'
        SET bp.gate_id = ga.gate_id,
            bp.boarding_time = DATE_SUB(
                (SELECT scheduled_departure FROM flights WHERE flight_id = v_flight_id),
                INTERVAL 30 MINUTE)
        WHERE bp.booking_id = p_booking_id;
        
        COMMIT;
        SET p_result = CONCAT('SUCCESS: Passenger checked in. Seat: ', COALESCE(p_seat, 'unchanged'));
    END IF;
END//

-- ============================================================
-- STORED PROCEDURE 6: Transfer passenger to another flight
-- ============================================================
DROP PROCEDURE IF EXISTS sp_transfer_passenger//
CREATE PROCEDURE sp_transfer_passenger(
    IN p_booking_id INT,
    IN p_new_flight_id INT,
    IN p_new_seat VARCHAR(4),
    OUT p_result VARCHAR(200)
)
BEGIN
    DECLARE v_passenger_id INT;
    DECLARE v_class VARCHAR(20);
    DECLARE v_new_available INT;
    DECLARE v_new_price DECIMAL(10,2);
    DECLARE v_new_ref VARCHAR(6);
    DECLARE v_new_booking_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_result = 'ERROR: Transfer failed';
    END;
    
    START TRANSACTION;
    
    SELECT passenger_id, booking_class
    INTO v_passenger_id, v_class
    FROM bookings
    WHERE booking_id = p_booking_id AND booking_status IN ('CONFIRMED', 'CHECKED_IN')
    FOR UPDATE;
    
    IF v_passenger_id IS NULL THEN
        ROLLBACK;
        SET p_result = 'ERROR: Active booking not found';
    ELSE
        SELECT available_seats, base_price
        INTO v_new_available, v_new_price
        FROM flights WHERE flight_id = p_new_flight_id FOR UPDATE;
        
        IF v_new_available <= 0 THEN
            ROLLBACK;
            SET p_result = 'ERROR: No seats on new flight';
        ELSE
            -- Cancel old booking
            UPDATE bookings SET booking_status = 'CANCELLED' WHERE booking_id = p_booking_id;
            UPDATE flights SET available_seats = available_seats + 1 
            WHERE flight_id = (SELECT flight_id FROM bookings WHERE booking_id = p_booking_id);
            
            -- Create new booking
            SET v_new_ref = UPPER(SUBSTRING(MD5(CONCAT(v_passenger_id, p_new_flight_id, NOW())), 1, 6));
            INSERT INTO bookings (booking_ref, passenger_id, flight_id, booking_class, seat_number, price, booking_status, payment_status)
            VALUES (v_new_ref, v_passenger_id, p_new_flight_id, v_class, p_new_seat, v_new_price, 'CONFIRMED', 'PAID');
            
            SET v_new_booking_id = LAST_INSERT_ID();
            
            UPDATE flights SET available_seats = available_seats - 1 WHERE flight_id = p_new_flight_id;
            
            -- Transfer baggage records
            UPDATE baggage SET booking_id = v_new_booking_id WHERE booking_id = p_booking_id;
            
            COMMIT;
            SET p_result = CONCAT('SUCCESS: Transferred to flight. New ref: ', v_new_ref);
        END IF;
    END IF;
END//

DELIMITER ;
