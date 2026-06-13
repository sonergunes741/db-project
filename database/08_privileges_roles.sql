-- ============================================================
-- SKYPORT INTERNATIONAL AIRPORT DATABASE
-- 08_privileges_roles.sql — Roles & Permissions
-- ============================================================

USE skyport_airport;

-- ============================================================
-- CREATE ROLES
-- ============================================================

-- Drop existing roles if they exist (MySQL 8.0+)
DROP ROLE IF EXISTS 'airport_admin';
DROP ROLE IF EXISTS 'airline_manager';
DROP ROLE IF EXISTS 'check_in_agent';
DROP ROLE IF EXISTS 'maintenance_crew';
DROP ROLE IF EXISTS 'shop_manager';
DROP ROLE IF EXISTS 'readonly_analyst';

-- Create roles
CREATE ROLE 'airport_admin';
CREATE ROLE 'airline_manager';
CREATE ROLE 'check_in_agent';
CREATE ROLE 'maintenance_crew';
CREATE ROLE 'shop_manager';
CREATE ROLE 'readonly_analyst';

-- ============================================================
-- GRANT PRIVILEGES TO ROLES
-- ============================================================

-- AIRPORT ADMIN: Full access to everything
GRANT ALL PRIVILEGES ON skyport_airport.* TO 'airport_admin';

-- AIRLINE MANAGER: Manage flights, bookings, crew for their airline
GRANT SELECT, INSERT, UPDATE ON skyport_airport.flights TO 'airline_manager';
GRANT SELECT, INSERT, UPDATE ON skyport_airport.bookings TO 'airline_manager';
GRANT SELECT, INSERT, UPDATE, DELETE ON skyport_airport.flight_crew_assignments TO 'airline_manager';
GRANT SELECT ON skyport_airport.airlines TO 'airline_manager';
GRANT SELECT ON skyport_airport.aircraft TO 'airline_manager';
GRANT SELECT ON skyport_airport.aircraft_types TO 'airline_manager';
GRANT SELECT ON skyport_airport.passengers TO 'airline_manager';
GRANT SELECT ON skyport_airport.boarding_passes TO 'airline_manager';
GRANT SELECT ON skyport_airport.baggage TO 'airline_manager';
GRANT SELECT ON skyport_airport.vw_flight_dashboard TO 'airline_manager';
GRANT SELECT ON skyport_airport.vw_airline_statistics TO 'airline_manager';
GRANT SELECT ON skyport_airport.vw_revenue_report TO 'airline_manager';
GRANT SELECT ON skyport_airport.vw_crew_schedule TO 'airline_manager';
GRANT EXECUTE ON PROCEDURE skyport_airport.sp_book_flight TO 'airline_manager';
GRANT EXECUTE ON PROCEDURE skyport_airport.sp_cancel_booking TO 'airline_manager';

-- CHECK-IN AGENT: Read passengers, update bookings, create boarding passes
GRANT SELECT ON skyport_airport.passengers TO 'check_in_agent';
GRANT SELECT ON skyport_airport.flights TO 'check_in_agent';
GRANT SELECT, UPDATE ON skyport_airport.bookings TO 'check_in_agent';
GRANT SELECT, INSERT, UPDATE ON skyport_airport.boarding_passes TO 'check_in_agent';
GRANT SELECT, INSERT ON skyport_airport.baggage TO 'check_in_agent';
GRANT SELECT ON skyport_airport.gates TO 'check_in_agent';
GRANT SELECT ON skyport_airport.gate_assignments TO 'check_in_agent';
GRANT SELECT ON skyport_airport.vw_passenger_itinerary TO 'check_in_agent';
GRANT SELECT ON skyport_airport.vw_gate_availability TO 'check_in_agent';
GRANT EXECUTE ON PROCEDURE skyport_airport.sp_check_in_passenger TO 'check_in_agent';

-- MAINTENANCE CREW: Manage maintenance records, read aircraft
GRANT SELECT ON skyport_airport.aircraft TO 'maintenance_crew';
GRANT SELECT ON skyport_airport.aircraft_types TO 'maintenance_crew';
GRANT SELECT, INSERT, UPDATE ON skyport_airport.maintenance_records TO 'maintenance_crew';
GRANT SELECT ON skyport_airport.flights TO 'maintenance_crew';
GRANT SELECT ON skyport_airport.vw_maintenance_status TO 'maintenance_crew';

-- SHOP MANAGER: Manage shops and transactions
GRANT SELECT, INSERT, UPDATE ON skyport_airport.shops TO 'shop_manager';
GRANT SELECT, INSERT ON skyport_airport.shop_transactions TO 'shop_manager';
GRANT SELECT ON skyport_airport.passengers TO 'shop_manager';
GRANT SELECT ON skyport_airport.frequent_flyer TO 'shop_manager';
GRANT SELECT ON skyport_airport.terminals TO 'shop_manager';

-- READONLY ANALYST: SELECT only on all views
GRANT SELECT ON skyport_airport.vw_flight_dashboard TO 'readonly_analyst';
GRANT SELECT ON skyport_airport.vw_passenger_itinerary TO 'readonly_analyst';
GRANT SELECT ON skyport_airport.vw_airline_statistics TO 'readonly_analyst';
GRANT SELECT ON skyport_airport.vw_gate_availability TO 'readonly_analyst';
GRANT SELECT ON skyport_airport.vw_baggage_tracking TO 'readonly_analyst';
GRANT SELECT ON skyport_airport.vw_crew_schedule TO 'readonly_analyst';
GRANT SELECT ON skyport_airport.vw_maintenance_status TO 'readonly_analyst';
GRANT SELECT ON skyport_airport.vw_revenue_report TO 'readonly_analyst';
GRANT SELECT ON skyport_airport.vw_delayed_flights TO 'readonly_analyst';
GRANT SELECT ON skyport_airport.vw_employee_directory TO 'readonly_analyst';
GRANT SELECT ON skyport_airport.vw_parking_availability TO 'readonly_analyst';

-- ============================================================
-- CREATE USERS AND ASSIGN ROLES
-- ============================================================

-- Drop existing users if they exist
DROP USER IF EXISTS 'admin_user'@'localhost';
DROP USER IF EXISTS 'tk_manager'@'localhost';
DROP USER IF EXISTS 'checkin_agent1'@'localhost';
DROP USER IF EXISTS 'maint_tech1'@'localhost';
DROP USER IF EXISTS 'shop_mgr1'@'localhost';
DROP USER IF EXISTS 'analyst1'@'localhost';

-- Create users
CREATE USER 'admin_user'@'localhost' IDENTIFIED BY 'Admin@SkyPort2026!';
CREATE USER 'tk_manager'@'localhost' IDENTIFIED BY 'TKManager2026!';
CREATE USER 'checkin_agent1'@'localhost' IDENTIFIED BY 'CheckIn2026!';
CREATE USER 'maint_tech1'@'localhost' IDENTIFIED BY 'Maint2026!';
CREATE USER 'shop_mgr1'@'localhost' IDENTIFIED BY 'Shop2026!';
CREATE USER 'analyst1'@'localhost' IDENTIFIED BY 'Analyst2026!';

-- Assign roles to users
GRANT 'airport_admin' TO 'admin_user'@'localhost';
GRANT 'airline_manager' TO 'tk_manager'@'localhost';
GRANT 'check_in_agent' TO 'checkin_agent1'@'localhost';
GRANT 'maintenance_crew' TO 'maint_tech1'@'localhost';
GRANT 'shop_manager' TO 'shop_mgr1'@'localhost';
GRANT 'readonly_analyst' TO 'analyst1'@'localhost';

-- Set default roles (activated on login)
SET DEFAULT ROLE 'airport_admin' TO 'admin_user'@'localhost';
SET DEFAULT ROLE 'airline_manager' TO 'tk_manager'@'localhost';
SET DEFAULT ROLE 'check_in_agent' TO 'checkin_agent1'@'localhost';
SET DEFAULT ROLE 'maintenance_crew' TO 'maint_tech1'@'localhost';
SET DEFAULT ROLE 'shop_manager' TO 'shop_mgr1'@'localhost';
SET DEFAULT ROLE 'readonly_analyst' TO 'analyst1'@'localhost';

FLUSH PRIVILEGES;

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Show all roles
SELECT * FROM mysql.user WHERE host = 'localhost' AND user IN 
    ('admin_user', 'tk_manager', 'checkin_agent1', 'maint_tech1', 'shop_mgr1', 'analyst1');

-- Show grants for each role
SHOW GRANTS FOR 'airport_admin';
SHOW GRANTS FOR 'airline_manager';
SHOW GRANTS FOR 'check_in_agent';
SHOW GRANTS FOR 'maintenance_crew';
SHOW GRANTS FOR 'shop_manager';
SHOW GRANTS FOR 'readonly_analyst';
