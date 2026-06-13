# SkyPort Airport DBMS — Test Scenarios

Use this guide to systematically test every feature of the database. Each scenario includes the **what**, **how**, and **expected result**.

---

## 🔧 Setup Checklist

1. MySQL 8.0+ is installed and running
2. Run SQL files in order:
   ```
   mysql -u root -p < database/01_create_database.sql
   mysql -u root -p skyport_airport < database/02_triggers.sql
   mysql -u root -p skyport_airport < database/03_functions_procedures.sql
   mysql -u root -p skyport_airport < database/04_views.sql
   mysql -u root -p skyport_airport < database/05_seed_data.sql
   ```
3. Install and start the server:
   ```
   cd server && npm install && npm start
   ```
4. Open `http://localhost:3000` in browser

---

## Module 1: Flight Management

### Test 1.1 — View Flight Dashboard
- **Action**: Click "Flight Management" in sidebar
- **Expected**: Table shows 20 flights with status badges, gate info, occupancy %

### Test 1.2 — Create New Flight
- **Action**: Click "+ Add Flight" → Fill form (TK999, SKP→MUC, set times) → Create
- **Expected**: Toast "Flight created", new row appears in table

### Test 1.3 — Update Flight Status (Trigger Test)
- **Action**: Click shortcut "Board TK1"
- **Expected**: TK1 status changes to BOARDING. The `trg_after_flight_status_update` trigger fires and logs to `flight_status_history`.

### Test 1.4 — Delay a Flight
- **Action**: Click shortcut "Delay LH401"
- **Expected**: LH401 shows DELAYED (30 min, ATC restrictions). Status history records the delay.

### Test 1.5 — Cancel a Flight
- **Action**: Click shortcut "Cancel AF501"
- **Expected**: AF501 shows CANCELLED. History trigger records reason.

### Test 1.6 — View Status History
- **Action**: Click shortcut "TK1 History" or click 📜 icon on TK1
- **Expected**: Shows chronological list of status changes with timestamps

### Test 1.7 — Delete Flight (Trigger Test)
- **Action**: Try to delete a flight with active bookings (e.g., TK1)
- **Expected**: Error toast! `trg_before_flight_delete` prevents deletion.

### Test 1.8 — Delete Flight without Bookings
- **Action**: Delete the newly created TK999 (no bookings)
- **Expected**: Success — flight is removed

---

## Module 2: Passengers & Bookings

### Test 2.1 — View Passengers
- **Action**: Click "Passengers & Bookings" → Passengers tab
- **Expected**: 25 passengers displayed with name, email, passport, nationality

### Test 2.2 — Search Passengers
- **Action**: Type "Ahmet" in search box
- **Expected**: Filters to show Ahmet Yilmaz only

### Test 2.3 — Add New Passenger
- **Action**: Click "+ Add Passenger" → Fill form → Add
- **Expected**: New passenger appears in list

### Test 2.4 — Book a Flight (Transaction + Trigger Test)
- **Action**: Click shortcut "Book Chen→TK1"
- **Expected**: 
  - Booking created (stored procedure `sp_book_flight` runs as transaction)
  - Boarding pass auto-created (trigger `trg_after_booking_insert`)
  - Available seats decreased by 1
  - Audit log entry created (trigger `trg_audit_booking_insert`)
  - Frequent flyer miles awarded (if member)

### Test 2.5 — Check-in Passenger (Transaction Test)
- **Action**: Click shortcut "Check-in Booking#1"
- **Expected**: Status changes from CONFIRMED → CHECKED_IN via `sp_check_in_passenger`

### Test 2.6 — Cancel Booking (Transaction Test)
- **Action**: Click shortcut "Cancel Booking#8"
- **Expected**:
  - Booking status → CANCELLED, Payment → REFUNDED
  - Seat released (available_seats +1)
  - Miles deducted from frequent flyer

### Test 2.7 — Transfer Passenger (Transaction Test)
- **Action**: Click shortcut "Transfer Booking#13"
- **Expected**:
  - Old booking cancelled, new booking created
  - Baggage records transferred to new booking
  - Both flights' available_seats updated

### Test 2.8 — View Itinerary
- **Action**: Click shortcut "Ahmet Itinerary"
- **Expected**: Shows all flights for Ahmet Yilmaz with gate, boarding group

### Test 2.9 — View Frequent Flyer
- **Action**: Click "Frequent Flyer" tab
- **Expected**: 15 members listed with tier badges (BASIC/SILVER/GOLD/PLATINUM)

---

## Module 3: Baggage & Cargo

### Test 3.1 — View Baggage
- **Action**: Click "Baggage & Cargo"
- **Expected**: 25 baggage items with tag, weight, status, and any claims

### Test 3.2 — Add Baggage (Trigger Test)
- **Action**: Click shortcut "Add Bag→Booking#1"
- **Expected**: New baggage added. Trigger `trg_before_baggage_insert` validates weight limit.

### Test 3.3 — Exceed Baggage Weight
- **Action**: Via SQL Console: Try adding a 50kg CHECKED bag to an ECONOMY booking
- **Expected**: Error! Trigger rejects: "Baggage exceeds maximum weight limit"

### Test 3.4 — Update Baggage Status
- **Action**: Click shortcuts "Load Bag#1" then "Arrive Bag#1"
- **Expected**: Status changes CHECKED_IN → LOADED → ARRIVED

### Test 3.5 — File Baggage Claim (Trigger Test)
- **Action**: Click shortcut "File Lost Claim"
- **Expected**: Claim created. Trigger `trg_after_baggage_claim_insert` updates baggage status to LOST.

### Test 3.6 — View Cargo
- **Action**: Click "Cargo Shipments" tab
- **Expected**: 8 cargo shipments displayed with types, weights, prices

---

## Module 4: Employee Management

### Test 4.1 — View Employee Directory (Inheritance Demo)
- **Action**: Click "Employee Management"
- **Expected**: 30 employees shown with TYPE column showing inheritance (PILOT, CABIN_CREW, GROUND_STAFF, SECURITY). The Specialization column shows type-specific details from child tables.

### Test 4.2 — View Crew Schedule
- **Action**: Click "Crew Schedule" tab
- **Expected**: Shows crew assignments to flights with their roles

### Test 4.3 — Delete Protected Employee (Trigger Test)
- **Action**: Via SQL Console: `SELECT * FROM flight_crew_assignments WHERE employee_id = 1;` then try to delete employee 1
- **Expected**: Error! `trg_before_employee_delete` prevents deletion of crew assigned to future flights.

---

## Module 5: Airport Operations

### Test 5.1 — View Gates
- **Action**: Click "Airport Operations"
- **Expected**: 20 gates shown with availability status, assigned flights

### Test 5.2 — Reassign Gate (Transaction Test)
- **Action**: Click shortcut "Reassign TK1→A5"
- **Expected**: Gate A1 freed, Gate A5 assigned. The `sp_reassign_gate` procedure runs atomically.

### Test 5.3 — Gate Conflict (Trigger Test)
- **Action**: Try assigning two flights to same gate at overlapping times
- **Expected**: Error! `trg_before_gate_assignment` prevents conflict.

### Test 5.4 — View Terminals
- **Action**: Click "Terminals" tab
- **Expected**: 4 terminals (A, B, C, D) with features

### Test 5.5 — View Runways
- **Action**: Click "Runways" tab
- **Expected**: 3 runways with specs

### Test 5.6 — View Maintenance (Trigger Test)
- **Action**: Click "Maintenance" tab
- **Expected**: 5 records. Note aircraft TC-JOE status is MAINTENANCE (set by `trg_after_maintenance_insert`)

### Test 5.7 — View Fleet
- **Action**: Click "Fleet" tab
- **Expected**: 16 aircraft with type, airline, flight hours

### Test 5.8 — View Airline Statistics (View Test)
- **Action**: Click "Airline Stats" tab
- **Expected**: Shows `vw_airline_statistics` view data — revenue, occupancy, delays per airline

---

## Module 6: Commercial & Parking

### Test 6.1 — View Shops
- **Action**: Click "Commercial & Parking"
- **Expected**: 8 shops displayed

### Test 6.2 — View Shop Transactions (Trigger Test)
- **Action**: Click "Transactions" tab
- **Expected**: 12 transactions. Note: `trg_after_shop_transaction` triggers award miles to frequent flyer members.

### Test 6.3 — View Parking (Trigger Test)
- **Action**: Click "Parking" tab
- **Expected**: 4 lots with occupancy. `trg_after_parking_reservation` auto-updates available spots.

---

## Module 7: Admin Panel

### Test 7.1 — View DB Stats
- **Action**: Click "Admin Panel"
- **Expected**: Stat cards show count of tables, views, triggers, routines

### Test 7.2 — SQL Console — LEFT JOIN
- **Action**: Click "LEFT JOIN" shortcut → Execute
- **Expected**: Shows ALL flights including those WITHOUT gate assignments (NULL gate values)

### Test 7.3 — SQL Console — RIGHT JOIN
- **Action**: Click "RIGHT JOIN" shortcut → Execute
- **Expected**: Shows ALL gates including those WITHOUT flight assignments

### Test 7.4 — SQL Console — FULL JOIN
- **Action**: Click "FULL JOIN" shortcut → Execute
- **Expected**: Shows employees without flights AND flights without crew (emulated with UNION)

### Test 7.5 — SQL Console — Custom Functions
- **Action**: Click "Use Functions" shortcut → Execute
- **Expected**: Shows flight duration and occupancy using `fn_calculate_flight_duration` and `fn_flight_occupancy`

### Test 7.6 — SQL Console — Window Functions
- **Action**: Click "Window Funcs" shortcut → Execute
- **Expected**: Shows passenger spending with RANK, DENSE_RANK, and partition totals

### Test 7.7 — SQL Console — CTE
- **Action**: Click "CTE Query" shortcut → Execute
- **Expected**: Shows airline reliability ratings using Common Table Expressions

### Test 7.8 — Audit Log
- **Action**: Click "Audit Log" tab
- **Expected**: Shows all logged operations from triggers

### Test 7.9 — DB Info
- **Action**: Click "DB Info" tab
- **Expected**: Lists all tables (with row counts), triggers, functions/procedures, and views

---

## Advanced SQL Scenarios (via SQL Console)

### Test A.1 — Subquery
```sql
SELECT CONCAT(p.first_name, ' ', p.last_name) AS name, SUM(b.price) AS total
FROM passengers p JOIN bookings b ON p.passenger_id = b.passenger_id
WHERE b.payment_status = 'PAID'
GROUP BY p.passenger_id HAVING total > (SELECT AVG(price) * 2 FROM bookings WHERE payment_status = 'PAID')
ORDER BY total DESC;
```

### Test A.2 — EXISTS
```sql
SELECT p.passenger_id, CONCAT(p.first_name, ' ', p.last_name) AS name
FROM passengers p
WHERE EXISTS (SELECT 1 FROM bookings b WHERE b.passenger_id = p.passenger_id AND b.booking_status != 'CANCELLED')
AND EXISTS (SELECT 1 FROM shop_transactions st WHERE st.passenger_id = p.passenger_id);
```

### Test A.3 — Self-Join (Connecting Flights)
```sql
SELECT f1.flight_number AS first_leg, f1.destination_airport AS connection,
       f2.flight_number AS second_leg, f2.destination_airport AS final_dest,
       TIMESTAMPDIFF(MINUTE, f1.scheduled_arrival, f2.scheduled_departure) AS layover_min
FROM flights f1 JOIN flights f2 ON f1.destination_airport = f2.origin_airport
    AND f2.scheduled_departure > f1.scheduled_arrival
    AND TIMESTAMPDIFF(MINUTE, f1.scheduled_arrival, f2.scheduled_departure) BETWEEN 60 AND 360
WHERE f1.status != 'CANCELLED' AND f2.status != 'CANCELLED';
```

### Test A.4 — Revenue by Route
```sql
SELECT f.origin_airport, f.destination_airport,
       SUM(CASE WHEN b.booking_class = 'ECONOMY' THEN b.price ELSE 0 END) AS economy_rev,
       SUM(CASE WHEN b.booking_class = 'BUSINESS' THEN b.price ELSE 0 END) AS business_rev,
       SUM(b.price) AS total
FROM flights f JOIN bookings b ON f.flight_id = b.flight_id
WHERE b.booking_status != 'CANCELLED'
GROUP BY f.origin_airport, f.destination_airport ORDER BY total DESC;
```

---

## Transaction Atomicity Tests

### Test T.1 — Verify Atomicity
1. Note available seats on TK1
2. Run "Book Chen→TK1" 
3. Verify: seats decreased by 1, booking created, boarding pass created, miles awarded
4. All 4 operations happened together (atomic)

### Test T.2 — Verify Rollback
1. Try booking on cancelled flight TK3 (flight_id=20)
2. Via SQL: `CALL sp_book_flight(1, 20, 'ECONOMY', '10A', @id, @res); SELECT @res;`
3. Verify: no booking created, no seats changed (rolled back)

### Test T.3 — Verify Cancellation Rollback
1. Cancel a booking
2. Verify: seat released, refund processed, miles deducted — all atomically

---

## Trigger Verification Summary

| # | Trigger | Test Action | Expected |
|---|---------|------------|----------|
| 1 | `trg_after_booking_insert` | Book a flight | Boarding pass auto-created |
| 2 | `trg_after_flight_status_update` | Change flight status | History logged |
| 3 | `trg_before_baggage_insert` | Add 50kg bag to economy | Rejected |
| 4 | `trg_after_baggage_claim_insert` | File claim | Baggage status updated |
| 5 | `trg_before_employee_delete` | Delete assigned pilot | Prevented |
| 6 | `trg_after_maintenance_insert` | Add IN_PROGRESS maintenance | Aircraft → MAINTENANCE |
| 7 | `trg_after_maintenance_complete` | Complete maintenance | Aircraft → ACTIVE |
| 8 | `trg_after_shop_transaction` | Make purchase | FF miles awarded |
| 9 | `trg_before_gate_assignment` | Double-assign gate | Conflict prevented |
| 10 | `trg_audit_booking_insert` | Create booking | Audit log entry |
| 11 | `trg_after_parking_reservation` | Park car | Available spots -1 |
| 12 | `trg_before_flight_delete` | Delete flight w/ bookings | Prevented |

---

## View Verification Summary

| # | View | How to Test | Data Source |
|---|------|------------|-------------|
| 1 | `vw_flight_dashboard` | Flight Management page | flights + airlines + aircraft + gates |
| 2 | `vw_passenger_itinerary` | Passenger itinerary tab | passengers + bookings + flights + boarding_passes |
| 3 | `vw_airline_statistics` | Airline Stats tab | airlines + flights + bookings |
| 4 | `vw_gate_availability` | Gates tab | gates + gate_assignments + flights |
| 5 | `vw_baggage_tracking` | Baggage tab | baggage + bookings + passengers + claims |
| 6 | `vw_crew_schedule` | Crew Schedule tab | flight_crew_assignments + employees + flights |
| 7 | `vw_maintenance_status` | Maintenance tab | maintenance_records + aircraft + employees |
| 8 | `vw_revenue_report` | SQL Console: Revenue Report | airlines + flights + bookings |
| 9 | `vw_delayed_flights` | SQL Console: Delayed Flights | flights + airlines + gate_assignments |
| 10 | `vw_employee_directory` | Employee Directory | employees + pilots + cabin_crew + ground_staff + security |
| 11 | `vw_parking_availability` | Parking tab | parking_lots + parking_reservations |
