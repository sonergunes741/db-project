-- ============================================================
-- SKYPORT INTERNATIONAL AIRPORT DATABASE
-- 02_triggers.sql — All Triggers (12)
-- ============================================================

USE skyport_airport;

DELIMITER //

-- ============================================================
-- TRIGGER 1: Auto-create boarding pass when booking is confirmed
-- ============================================================
DROP TRIGGER IF EXISTS trg_after_booking_insert//
CREATE TRIGGER trg_after_booking_insert
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    DECLARE v_barcode VARCHAR(30);
    SET v_barcode = CONCAT('BP', LPAD(NEW.booking_id, 8, '0'), FLOOR(RAND() * 1000));
    
    INSERT INTO boarding_passes (booking_id, boarding_group, barcode)
    VALUES (NEW.booking_id, 
            CASE NEW.booking_class 
                WHEN 'FIRST' THEN 'A'
                WHEN 'BUSINESS' THEN 'B'
                WHEN 'PREMIUM_ECONOMY' THEN 'C'
                ELSE 'D'
            END,
            v_barcode);
END//

-- ============================================================
-- TRIGGER 2: Log flight status changes
-- ============================================================
DROP TRIGGER IF EXISTS trg_after_flight_status_update//
CREATE TRIGGER trg_after_flight_status_update
AFTER UPDATE ON flights
FOR EACH ROW
BEGIN
    IF OLD.status != NEW.status THEN
        INSERT INTO flight_status_history (flight_id, old_status, new_status, notes)
        VALUES (NEW.flight_id, OLD.status, NEW.status,
                CASE 
                    WHEN NEW.status = 'DELAYED' THEN CONCAT('Delayed by ', NEW.delay_minutes, ' minutes. Reason: ', IFNULL(NEW.delay_reason, 'N/A'))
                    WHEN NEW.status = 'CANCELLED' THEN CONCAT('Flight cancelled. Reason: ', IFNULL(NEW.delay_reason, 'N/A'))
                    ELSE CONCAT('Status changed from ', OLD.status, ' to ', NEW.status)
                END);
    END IF;
END//

-- ============================================================
-- TRIGGER 3: Validate baggage weight limits
-- ============================================================
DROP TRIGGER IF EXISTS trg_before_baggage_insert//
CREATE TRIGGER trg_before_baggage_insert
BEFORE INSERT ON baggage
FOR EACH ROW
BEGIN
    DECLARE v_class ENUM('ECONOMY','PREMIUM_ECONOMY','BUSINESS','FIRST');
    DECLARE v_max_weight DECIMAL(5,2);
    DECLARE v_current_total DECIMAL(10,2);
    
    SELECT booking_class INTO v_class FROM bookings WHERE booking_id = NEW.booking_id;
    
    SET v_max_weight = CASE v_class
        WHEN 'ECONOMY' THEN 23.00
        WHEN 'PREMIUM_ECONOMY' THEN 28.00
        WHEN 'BUSINESS' THEN 32.00
        WHEN 'FIRST' THEN 40.00
        ELSE 23.00
    END;
    
    IF NEW.baggage_type = 'CHECKED' AND NEW.weight_kg > v_max_weight THEN
        SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Baggage exceeds maximum weight limit for booking class';
    END IF;
    
    -- Check total baggage count per booking (max 3 for economy, 5 for business/first)
    SELECT COUNT(*) INTO v_current_total FROM baggage WHERE booking_id = NEW.booking_id AND baggage_type = 'CHECKED';
    
    IF v_class IN ('ECONOMY', 'PREMIUM_ECONOMY') AND v_current_total >= 3 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Maximum checked baggage limit reached for economy class';
    ELSEIF v_class IN ('BUSINESS', 'FIRST') AND v_current_total >= 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Maximum checked baggage limit reached';
    END IF;
END//

-- ============================================================
-- TRIGGER 4: Update baggage status on claim
-- ============================================================
DROP TRIGGER IF EXISTS trg_after_baggage_claim_insert//
CREATE TRIGGER trg_after_baggage_claim_insert
AFTER INSERT ON baggage_claims
FOR EACH ROW
BEGIN
    UPDATE baggage 
    SET status = CASE NEW.claim_type 
        WHEN 'LOST' THEN 'LOST'
        WHEN 'DAMAGED' THEN 'DAMAGED'
        ELSE status 
    END,
    updated_at = CURRENT_TIMESTAMP
    WHERE baggage_id = NEW.baggage_id;
END//

-- ============================================================
-- TRIGGER 5: Prevent deleting employees assigned to future flights
-- ============================================================
DROP TRIGGER IF EXISTS trg_before_employee_delete//
CREATE TRIGGER trg_before_employee_delete
BEFORE DELETE ON employees
FOR EACH ROW
BEGIN
    DECLARE v_future_flights INT;
    
    SELECT COUNT(*) INTO v_future_flights 
    FROM flight_crew_assignments fca
    JOIN flights f ON fca.flight_id = f.flight_id
    WHERE fca.employee_id = OLD.employee_id 
      AND f.scheduled_departure > NOW()
      AND f.status NOT IN ('CANCELLED', 'ARRIVED');
    
    IF v_future_flights > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete employee assigned to future flights';
    END IF;
END//

-- ============================================================
-- TRIGGER 6: Set aircraft to MAINTENANCE when maintenance starts
-- ============================================================
DROP TRIGGER IF EXISTS trg_after_maintenance_insert//
CREATE TRIGGER trg_after_maintenance_insert
AFTER INSERT ON maintenance_records
FOR EACH ROW
BEGIN
    IF NEW.status = 'IN_PROGRESS' THEN
        UPDATE aircraft 
        SET status = 'MAINTENANCE',
            last_maintenance = CURDATE(),
            updated_at = CURRENT_TIMESTAMP
        WHERE aircraft_id = NEW.aircraft_id;
    END IF;
END//

-- ============================================================
-- TRIGGER 7: Restore aircraft when maintenance completes
-- ============================================================
DROP TRIGGER IF EXISTS trg_after_maintenance_complete//
CREATE TRIGGER trg_after_maintenance_complete
AFTER UPDATE ON maintenance_records
FOR EACH ROW
BEGIN
    IF NEW.status = 'COMPLETED' AND OLD.status != 'COMPLETED' THEN
        UPDATE aircraft 
        SET status = 'ACTIVE',
            last_maintenance = CURDATE(),
            next_maintenance = DATE_ADD(CURDATE(), INTERVAL 90 DAY),
            updated_at = CURRENT_TIMESTAMP
        WHERE aircraft_id = NEW.aircraft_id;
    END IF;
END//

-- ============================================================
-- TRIGGER 8: Award frequent flyer miles on shop purchases
-- ============================================================
DROP TRIGGER IF EXISTS trg_after_shop_transaction//
CREATE TRIGGER trg_after_shop_transaction
AFTER INSERT ON shop_transactions
FOR EACH ROW
BEGIN
    DECLARE v_miles INT;
    
    IF NEW.passenger_id IS NOT NULL THEN
        -- Award 1 mile per $2 spent
        SET v_miles = FLOOR(NEW.amount / 2);
        
        UPDATE frequent_flyer 
        SET total_miles = total_miles + v_miles,
            available_miles = available_miles + v_miles,
            last_activity = CURDATE()
        WHERE passenger_id = NEW.passenger_id;
    END IF;
END//

-- ============================================================
-- TRIGGER 9: Check gate availability before assignment
-- ============================================================
DROP TRIGGER IF EXISTS trg_before_gate_assignment//
CREATE TRIGGER trg_before_gate_assignment
BEFORE INSERT ON gate_assignments
FOR EACH ROW
BEGIN
    DECLARE v_conflicts INT;
    
    SELECT COUNT(*) INTO v_conflicts
    FROM gate_assignments
    WHERE gate_id = NEW.gate_id
      AND status = 'ACTIVE'
      AND ((NEW.start_time BETWEEN start_time AND end_time)
           OR (NEW.end_time BETWEEN start_time AND end_time)
           OR (start_time BETWEEN NEW.start_time AND NEW.end_time));
    
    IF v_conflicts > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Gate is already assigned to another flight during this time period';
    END IF;
    
    -- Also update gate availability
    UPDATE gates SET is_available = FALSE WHERE gate_id = NEW.gate_id;
END//

-- ============================================================
-- TRIGGER 10: Audit log for bookings
-- ============================================================
DROP TRIGGER IF EXISTS trg_audit_booking_insert//
CREATE TRIGGER trg_audit_booking_insert
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, new_values)
    VALUES ('bookings', 'INSERT', NEW.booking_id,
            JSON_OBJECT('booking_ref', NEW.booking_ref, 'passenger_id', NEW.passenger_id,
                        'flight_id', NEW.flight_id, 'class', NEW.booking_class,
                        'price', NEW.price, 'status', NEW.booking_status));
END//

DROP TRIGGER IF EXISTS trg_audit_booking_update//
CREATE TRIGGER trg_audit_booking_update
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (table_name, operation, record_id, old_values, new_values)
    VALUES ('bookings', 'UPDATE', NEW.booking_id,
            JSON_OBJECT('status', OLD.booking_status, 'payment', OLD.payment_status, 'seat', OLD.seat_number),
            JSON_OBJECT('status', NEW.booking_status, 'payment', NEW.payment_status, 'seat', NEW.seat_number));
END//

-- ============================================================
-- TRIGGER 11: Update parking lot spots on reservation
-- ============================================================
DROP TRIGGER IF EXISTS trg_after_parking_reservation//
CREATE TRIGGER trg_after_parking_reservation
AFTER INSERT ON parking_reservations
FOR EACH ROW
BEGIN
    IF NEW.status = 'ACTIVE' THEN
        UPDATE parking_lots 
        SET available_spots = available_spots - 1
        WHERE lot_id = NEW.lot_id AND available_spots > 0;
    END IF;
END//

DROP TRIGGER IF EXISTS trg_after_parking_complete//
CREATE TRIGGER trg_after_parking_complete
AFTER UPDATE ON parking_reservations
FOR EACH ROW
BEGIN
    IF NEW.status = 'COMPLETED' AND OLD.status = 'ACTIVE' THEN
        UPDATE parking_lots 
        SET available_spots = available_spots + 1
        WHERE lot_id = NEW.lot_id;
    END IF;
END//

-- ============================================================
-- TRIGGER 12: Prevent deleting flights with active bookings
-- ============================================================
DROP TRIGGER IF EXISTS trg_before_flight_delete//
CREATE TRIGGER trg_before_flight_delete
BEFORE DELETE ON flights
FOR EACH ROW
BEGIN
    DECLARE v_active_bookings INT;
    
    SELECT COUNT(*) INTO v_active_bookings
    FROM bookings
    WHERE flight_id = OLD.flight_id
      AND booking_status IN ('CONFIRMED', 'CHECKED_IN');
    
    IF v_active_bookings > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete flight with active bookings. Cancel bookings first.';
    END IF;
END//

DELIMITER ;
