const express = require('express');
const mysql = require('mysql2/promise');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '..', 'public')));

// ============================================================
// DATABASE CONNECTION POOL
// ============================================================
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || '',
    database: 'skyport_airport',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    multipleStatements: true
});

// Test connection on startup
(async () => {
    try {
        const conn = await pool.getConnection();
        console.log('✅ Connected to MySQL - skyport_airport database');
        conn.release();
    } catch (err) {
        console.error('❌ MySQL connection failed:', err.message);
        console.log('Make sure MySQL is running and the database is created.');
        console.log('Run the SQL files in database/ folder first.');
    }
})();

// ============================================================
// HELPER: Execute query and return results
// ============================================================
async function query(sql, params = []) {
    const [rows] = await pool.execute(sql, params);
    return rows;
}

async function queryRaw(sql) {
    const [rows] = await pool.query(sql);
    return rows;
}

// ============================================================
// FLIGHTS ROUTES
// ============================================================

// Get all flights (dashboard)
app.get('/api/flights', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_flight_dashboard ORDER BY scheduled_departure`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get single flight
app.get('/api/flights/:id', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_flight_dashboard WHERE flight_id = ?`, [req.params.id]);
        res.json(rows[0] || null);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create flight
app.post('/api/flights', async (req, res) => {
    try {
        const { flight_number, airline_id, aircraft_id, origin_airport, destination_airport,
                scheduled_departure, scheduled_arrival, flight_type, total_seats, base_price } = req.body;
        const [result] = await pool.execute(
            `INSERT INTO flights (flight_number, airline_id, aircraft_id, origin_airport, destination_airport,
             scheduled_departure, scheduled_arrival, flight_type, total_seats, available_seats, base_price)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [flight_number, airline_id, aircraft_id, origin_airport, destination_airport,
             scheduled_departure, scheduled_arrival, flight_type, total_seats, total_seats, base_price]
        );
        res.json({ success: true, id: result.insertId, message: 'Flight created successfully' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Update flight status
app.put('/api/flights/:id/status', async (req, res) => {
    try {
        const { status, delay_minutes, delay_reason } = req.body;
        await pool.execute(
            `UPDATE flights SET status = ?, delay_minutes = ?, delay_reason = ? WHERE flight_id = ?`,
            [status, delay_minutes || 0, delay_reason || null, req.params.id]
        );
        res.json({ success: true, message: `Flight status updated to ${status}` });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Delete flight
app.delete('/api/flights/:id', async (req, res) => {
    try {
        await pool.execute(`DELETE FROM flights WHERE flight_id = ?`, [req.params.id]);
        res.json({ success: true, message: 'Flight deleted successfully' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get flight status history
app.get('/api/flights/:id/history', async (req, res) => {
    try {
        const rows = await query(
            `SELECT * FROM flight_status_history WHERE flight_id = ? ORDER BY changed_at DESC`, [req.params.id]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get delayed flights
app.get('/api/flights-delayed', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_delayed_flights`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ============================================================
// PASSENGERS & BOOKINGS ROUTES
// ============================================================

// Get all passengers
app.get('/api/passengers', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM passengers ORDER BY last_name, first_name`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Search passengers
app.get('/api/passengers/search/:term', async (req, res) => {
    try {
        const term = `%${req.params.term}%`;
        const rows = await query(
            `SELECT * FROM passengers WHERE first_name LIKE ? OR last_name LIKE ? OR passport_number LIKE ? OR email LIKE ?`,
            [term, term, term, term]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create passenger
app.post('/api/passengers', async (req, res) => {
    try {
        const { first_name, last_name, email, phone, passport_number, nationality, date_of_birth, gender } = req.body;
        const [result] = await pool.execute(
            `INSERT INTO passengers (first_name, last_name, email, phone, passport_number, nationality, date_of_birth, gender)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [first_name, last_name, email, phone, passport_number, nationality, date_of_birth, gender]
        );
        res.json({ success: true, id: result.insertId, message: 'Passenger created' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get passenger itinerary
app.get('/api/passengers/:id/itinerary', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_passenger_itinerary WHERE passenger_id = ?`, [req.params.id]);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get all bookings
app.get('/api/bookings', async (req, res) => {
    try {
        const rows = await query(`
            SELECT b.*, CONCAT(p.first_name, ' ', p.last_name) as passenger_name, 
                   f.flight_number, f.origin_airport, f.destination_airport, f.scheduled_departure
            FROM bookings b 
            JOIN passengers p ON b.passenger_id = p.passenger_id
            JOIN flights f ON b.flight_id = f.flight_id
            ORDER BY b.booking_date DESC
        `);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Book a flight (uses stored procedure with transaction)
app.post('/api/bookings/book', async (req, res) => {
    try {
        const { passenger_id, flight_id, booking_class, seat_number } = req.body;
        const conn = await pool.getConnection();
        await conn.execute(
            `CALL sp_book_flight(?, ?, ?, ?, @booking_id, @result)`,
            [passenger_id, flight_id, booking_class, seat_number]
        );
        const [[result]] = await conn.query(`SELECT @booking_id as booking_id, @result as result`);
        conn.release();
        res.json({ success: result.result.startsWith('SUCCESS'), ...result });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Cancel booking (uses stored procedure with transaction)
app.post('/api/bookings/:id/cancel', async (req, res) => {
    try {
        const conn = await pool.getConnection();
        await conn.execute(`CALL sp_cancel_booking(?, @result)`, [req.params.id]);
        const [[result]] = await conn.query(`SELECT @result as result`);
        conn.release();
        res.json({ success: result.result.startsWith('SUCCESS'), ...result });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Check-in passenger
app.post('/api/bookings/:id/checkin', async (req, res) => {
    try {
        const { seat_number } = req.body;
        const conn = await pool.getConnection();
        await conn.execute(`CALL sp_check_in_passenger(?, ?, @result)`, [req.params.id, seat_number || null]);
        const [[result]] = await conn.query(`SELECT @result as result`);
        conn.release();
        res.json({ success: result.result.startsWith('SUCCESS'), ...result });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Transfer passenger
app.post('/api/bookings/:id/transfer', async (req, res) => {
    try {
        const { new_flight_id, new_seat } = req.body;
        const conn = await pool.getConnection();
        await conn.execute(`CALL sp_transfer_passenger(?, ?, ?, @result)`, [req.params.id, new_flight_id, new_seat]);
        const [[result]] = await conn.query(`SELECT @result as result`);
        conn.release();
        res.json({ success: result.result.startsWith('SUCCESS'), ...result });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ============================================================
// BAGGAGE & CARGO ROUTES
// ============================================================

// Get baggage tracking
app.get('/api/baggage', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_baggage_tracking`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Add baggage
app.post('/api/baggage', async (req, res) => {
    try {
        const { booking_id, tag_number, weight_kg, baggage_type } = req.body;
        const [result] = await pool.execute(
            `INSERT INTO baggage (booking_id, tag_number, weight_kg, baggage_type) VALUES (?, ?, ?, ?)`,
            [booking_id, tag_number, weight_kg, baggage_type]
        );
        res.json({ success: true, id: result.insertId, message: 'Baggage added' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Update baggage status
app.put('/api/baggage/:id/status', async (req, res) => {
    try {
        await pool.execute(`UPDATE baggage SET status = ? WHERE baggage_id = ?`, [req.body.status, req.params.id]);
        res.json({ success: true, message: 'Baggage status updated' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// File baggage claim
app.post('/api/baggage-claims', async (req, res) => {
    try {
        const { baggage_id, passenger_id, claim_type, description } = req.body;
        const [result] = await pool.execute(
            `INSERT INTO baggage_claims (baggage_id, passenger_id, claim_type, description) VALUES (?, ?, ?, ?)`,
            [baggage_id, passenger_id, claim_type, description]
        );
        res.json({ success: true, id: result.insertId, message: 'Claim filed' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get cargo shipments
app.get('/api/cargo', async (req, res) => {
    try {
        const rows = await query(`
            SELECT cs.*, f.flight_number, f.origin_airport, f.destination_airport
            FROM cargo_shipments cs JOIN flights f ON cs.flight_id = f.flight_id
            ORDER BY cs.created_at DESC
        `);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ============================================================
// EMPLOYEE ROUTES
// ============================================================

// Get all employees (unified view)
app.get('/api/employees', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_employee_directory ORDER BY employee_type, full_name`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get crew schedule
app.get('/api/crew-schedule', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_crew_schedule ORDER BY scheduled_departure`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ============================================================
// OPERATIONS ROUTES (Gates, Runways, Terminals, Maintenance)
// ============================================================

// Get gate availability
app.get('/api/gates', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_gate_availability ORDER BY terminal_name, gate_number`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Reassign gate
app.post('/api/gates/reassign', async (req, res) => {
    try {
        const { flight_id, new_gate_id } = req.body;
        const conn = await pool.getConnection();
        await conn.execute(`CALL sp_reassign_gate(?, ?, @result)`, [flight_id, new_gate_id]);
        const [[result]] = await conn.query(`SELECT @result as result`);
        conn.release();
        res.json({ success: result.result.startsWith('SUCCESS'), ...result });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get terminals
app.get('/api/terminals', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM terminals`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get runways
app.get('/api/runways', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM runways`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get maintenance status
app.get('/api/maintenance', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_maintenance_status ORDER BY start_date DESC`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get airlines
app.get('/api/airlines', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM airlines ORDER BY airline_name`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get airline statistics
app.get('/api/airlines/stats', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_airline_statistics`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get aircraft
app.get('/api/aircraft', async (req, res) => {
    try {
        const rows = await query(`
            SELECT ac.*, at.manufacturer, at.model, at.type_code, a.airline_name
            FROM aircraft ac
            JOIN aircraft_types at ON ac.type_id = at.type_id
            JOIN airlines a ON ac.airline_id = a.airline_id
            ORDER BY a.airline_name, ac.registration_no
        `);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ============================================================
// COMMERCIAL & PARKING ROUTES
// ============================================================

// Get shops
app.get('/api/shops', async (req, res) => {
    try {
        const rows = await query(`
            SELECT s.*, t.terminal_name FROM shops s
            JOIN terminals t ON s.terminal_id = t.terminal_id ORDER BY t.terminal_name, s.shop_name
        `);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get shop transactions
app.get('/api/shop-transactions', async (req, res) => {
    try {
        const rows = await query(`
            SELECT st.*, s.shop_name, CONCAT(p.first_name, ' ', p.last_name) as customer_name
            FROM shop_transactions st
            JOIN shops s ON st.shop_id = s.shop_id
            LEFT JOIN passengers p ON st.passenger_id = p.passenger_id
            ORDER BY st.transaction_time DESC
        `);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get parking availability
app.get('/api/parking', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_parking_availability`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get frequent flyer info
app.get('/api/frequent-flyer', async (req, res) => {
    try {
        const rows = await query(`
            SELECT ff.*, CONCAT(p.first_name, ' ', p.last_name) as passenger_name, a.airline_name
            FROM frequent_flyer ff
            JOIN passengers p ON ff.passenger_id = p.passenger_id
            JOIN airlines a ON ff.airline_id = a.airline_id
            ORDER BY ff.total_miles DESC
        `);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ============================================================
// ADMIN ROUTES
// ============================================================

// Get audit log
app.get('/api/audit-log', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM audit_log ORDER BY performed_at DESC LIMIT 100`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Execute raw SQL (for demo/testing only)
app.post('/api/admin/query', async (req, res) => {
    try {
        const { sql } = req.body;
        // Safety check - only allow SELECT, CALL, SHOW, DESCRIBE
        const trimmed = sql.trim().toUpperCase();
        const allowed = ['SELECT', 'CALL', 'SHOW', 'DESCRIBE', 'DESC', 'EXPLAIN'];
        const isAllowed = allowed.some(cmd => trimmed.startsWith(cmd));
        
        if (!isAllowed) {
            return res.status(400).json({ error: 'Only SELECT, CALL, SHOW, and DESCRIBE queries are allowed in the admin panel.' });
        }
        
        const [rows] = await pool.query(sql);
        // Handle multiple result sets from CALL
        if (Array.isArray(rows) && rows.length > 0 && Array.isArray(rows[0])) {
            res.json(rows.filter(r => Array.isArray(r) && r.length > 0));
        } else {
            res.json(rows);
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get database stats
app.get('/api/admin/stats', async (req, res) => {
    try {
        const tables = await queryRaw(`
            SELECT TABLE_NAME, TABLE_ROWS, DATA_LENGTH, INDEX_LENGTH
            FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = 'skyport_airport'
            ORDER BY TABLE_NAME
        `);
        
        const triggers = await queryRaw(`
            SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE, ACTION_TIMING
            FROM information_schema.TRIGGERS 
            WHERE TRIGGER_SCHEMA = 'skyport_airport'
        `);
        
        const routines = await queryRaw(`
            SELECT ROUTINE_NAME, ROUTINE_TYPE
            FROM information_schema.ROUTINES 
            WHERE ROUTINE_SCHEMA = 'skyport_airport'
        `);
        
        const views = await queryRaw(`
            SELECT TABLE_NAME 
            FROM information_schema.VIEWS 
            WHERE TABLE_SCHEMA = 'skyport_airport'
        `);
        
        res.json({ tables, triggers, routines, views });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get revenue report view
app.get('/api/views/revenue', async (req, res) => {
    try {
        const rows = await query(`SELECT * FROM vw_revenue_report ORDER BY flight_date DESC, airline_name`);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// ============================================================
// START SERVER
// ============================================================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`
╔══════════════════════════════════════════════════════════╗
║     ✈️  SkyPort Airport Database Management System       ║
║     Server running on http://localhost:${PORT}              ║
╚══════════════════════════════════════════════════════════╝
    `);
});
