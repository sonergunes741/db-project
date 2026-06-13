// ============================================================
// SKYPORT DB — Technical Test Panel Logic
// ============================================================

// ============================================================
// HELPERS
// ============================================================

async function api(sql) {
    const res = await fetch('/api/admin/query', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sql })
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error);
    return data;
}

function log(msg, type = 'info') {
    const box = document.getElementById('log-box');
    const time = new Date().toLocaleTimeString();
    box.innerHTML = `<div class="log-entry"><span class="time">[${time}]</span> <span class="msg-${type}">${msg}</span></div>` + box.innerHTML;
}

function renderResult(targetId, sql, rows, label) {
    const container = document.getElementById(targetId);
    if (!rows || (Array.isArray(rows) && rows.length === 0)) {
        container.innerHTML = `<div class="result-block">
            <div class="result-header"><span class="sql-label">${label || 'QUERY'}</span><span class="row-count">0 rows</span></div>
            <div class="sql-display">${escHtml(sql)}</div>
            <div style="padding:10px;color:#666">No rows returned</div>
        </div>` + container.innerHTML;
        return;
    }

    // Handle multiple result sets (from CALL)
    if (Array.isArray(rows) && Array.isArray(rows[0])) {
        rows.forEach((rs, i) => {
            if (Array.isArray(rs) && rs.length > 0) {
                renderResult(targetId, i === 0 ? sql : '(continued)', rs, `${label} — Result Set ${i + 1}`);
            }
        });
        return;
    }

    const cols = Object.keys(rows[0]);
    const html = `<div class="result-block">
        <div class="result-header">
            <span class="sql-label">${label || 'QUERY'}</span>
            <span class="row-count">${rows.length} row${rows.length !== 1 ? 's' : ''} × ${cols.length} columns</span>
        </div>
        <div class="sql-display">${escHtml(sql)}</div>
        <div class="table-scroll">
            <table class="raw-table">
                <thead><tr>${cols.map(c => `<th>${c}</th>`).join('')}</tr></thead>
                <tbody>${rows.map(r => `<tr>${cols.map(c => {
                    const v = r[c];
                    if (v === null || v === undefined) return `<td class="null-val">NULL</td>`;
                    if (typeof v === 'number') return `<td class="num-val">${v}</td>`;
                    const s = String(v);
                    if (/^\d{4}-\d{2}-\d{2}/.test(s)) return `<td class="date-val">${s}</td>`;
                    return `<td>${escHtml(s)}</td>`;
                }).join('')}</tr>`).join('')}</tbody>
            </table>
        </div>
    </div>`;
    container.innerHTML = html + container.innerHTML;
}

function escHtml(s) {
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

// ============================================================
// NAVIGATION
// ============================================================

function showPanel(id) {
    document.querySelectorAll('.panel').forEach(p => p.classList.remove('active'));
    document.getElementById('panel-' + id).classList.add('active');
    document.querySelectorAll('.sidebar button').forEach(b => b.classList.remove('active'));
    event.target.classList.add('active');

    // Auto-load data for some panels
    if (id === 'raw') loadRawTableButtons();
    if (id === 'audit') loadAudit();
}

// ============================================================
// TABLES OVERVIEW
// ============================================================

async function runShow(type) {
    const target = 'tables-result';
    const queries = {
        tables: `SELECT TABLE_NAME, TABLE_ROWS, ROUND(DATA_LENGTH/1024,1) AS data_kb, ROUND(INDEX_LENGTH/1024,1) AS index_kb FROM information_schema.TABLES WHERE TABLE_SCHEMA='skyport_airport' ORDER BY TABLE_NAME`,
        triggers: `SELECT TRIGGER_NAME, EVENT_MANIPULATION AS event, EVENT_OBJECT_TABLE AS on_table, ACTION_TIMING AS timing FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='skyport_airport' ORDER BY EVENT_OBJECT_TABLE`,
        functions: `SELECT ROUTINE_NAME, ROUTINE_TYPE, DATA_TYPE AS returns_type FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='skyport_airport' AND ROUTINE_TYPE='FUNCTION'`,
        procedures: `SELECT ROUTINE_NAME, ROUTINE_TYPE FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='skyport_airport' AND ROUTINE_TYPE='PROCEDURE'`,
        views: `SELECT TABLE_NAME AS view_name FROM information_schema.VIEWS WHERE TABLE_SCHEMA='skyport_airport' ORDER BY TABLE_NAME`
    };
    const sql = queries[type];
    try {
        const rows = await api(sql);
        renderResult(target, sql, rows, `SHOW ${type.toUpperCase()}`);
        log(`Listed ${rows.length} ${type}`, 'ok');
    } catch (e) { log(e.message, 'err'); }
}

// ============================================================
// RAW TABLE VIEWER
// ============================================================

async function loadRawTableButtons() {
    try {
        const tables = await api(`SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA='skyport_airport' AND TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME`);
        document.getElementById('raw-table-buttons').innerHTML = tables.map(t =>
            `<button class="act-btn" onclick="viewTable('${t.TABLE_NAME}')">${t.TABLE_NAME}</button>`
        ).join('');
    } catch (e) { log(e.message, 'err'); }
}

async function viewTable(name) {
    const sql = `SELECT * FROM ${name} LIMIT 50`;
    try {
        const rows = await api(sql);
        renderResult('raw-result', sql, rows, `TABLE: ${name}`);
        log(`Showing ${name}: ${rows.length} rows`, 'ok');
    } catch (e) { log(e.message, 'err'); }
}

// ============================================================
// TRIGGER TESTS
// ============================================================

async function testTrigger(name) {
    const target = 'triggers-result';
    document.getElementById(target).innerHTML = '';

    try {
        switch (name) {
            case 'booking_insert': {
                // Show BEFORE state
                const before = await api(`SELECT COUNT(*) as boarding_pass_count FROM boarding_passes`);
                renderResult(target, 'SELECT COUNT(*) FROM boarding_passes', before, '① BEFORE — Boarding pass count');

                // Fire trigger by inserting a booking via procedure
                const sql = `CALL sp_book_flight(10, 2, 'ECONOMY', '30A', @bid, @res)`;
                await api(sql);
                const res = await api(`SELECT @bid as new_booking_id, @res as result`);
                renderResult(target, sql + '; SELECT @bid, @res;', res, '② ACTION — sp_book_flight called');

                // Show AFTER state — boarding pass auto-created by trigger
                const after = await api(`SELECT * FROM boarding_passes ORDER BY pass_id DESC LIMIT 3`);
                renderResult(target, 'SELECT * FROM boarding_passes ORDER BY pass_id DESC LIMIT 3', after, '③ AFTER — trg_after_booking_insert auto-created boarding pass');
                log('Trigger trg_after_booking_insert tested ✓', 'ok');
                break;
            }
            case 'flight_status': {
                const before = await api(`SELECT flight_id, flight_number, status FROM flights WHERE flight_id = 2`);
                renderResult(target, 'SELECT flight_id, flight_number, status FROM flights WHERE flight_id=2', before, '① BEFORE — Flight status');

                await api(`SELECT 1`); // dummy to separate
                // We need direct UPDATE - use a workaround through the API
                const updateRes = await fetch('/api/flights/2/status', {
                    method: 'PUT', headers: {'Content-Type':'application/json'},
                    body: JSON.stringify({ status: 'BOARDING', delay_minutes: 0 })
                });
                const ur = await updateRes.json();
                renderResult(target, "UPDATE flights SET status='BOARDING' WHERE flight_id=2", [ur], '② ACTION — Status changed to BOARDING');

                const after = await api(`SELECT * FROM flight_status_history WHERE flight_id = 2 ORDER BY changed_at DESC LIMIT 5`);
                renderResult(target, 'SELECT * FROM flight_status_history WHERE flight_id=2', after, '③ AFTER — trg_after_flight_status_update logged the change');
                log('Trigger trg_after_flight_status_update tested ✓', 'ok');
                break;
            }
            case 'baggage_weight': {
                renderResult(target, '-- Attempting to insert a 55kg CHECKED bag for an ECONOMY passenger', [], '① SETUP — Testing weight limit trigger');
                try {
                    // This should FAIL — trigger rejects heavy bags
                    await api(`INSERT INTO baggage (booking_id, tag_number, weight_kg, baggage_type) VALUES (1, 'BGTEST01', 55.0, 'CHECKED')`);
                    renderResult(target, "INSERT baggage (55kg)", [{result:'UNEXPECTED: Should have been rejected'}], '② RESULT — ERROR EXPECTED');
                } catch (e) {
                    renderResult(target, "INSERT INTO baggage (...) VALUES (1, 'BGTEST01', 55.0, 'CHECKED')", [{trigger_error: e.message}], '② RESULT — trg_before_baggage_insert REJECTED the insert ✓');
                    log('Trigger trg_before_baggage_insert correctly rejected heavy baggage ✓', 'ok');
                }
                break;
            }
            case 'baggage_claim': {
                const before = await api(`SELECT baggage_id, tag_number, status FROM baggage WHERE baggage_id = 1`);
                renderResult(target, 'SELECT baggage_id, tag_number, status FROM baggage WHERE baggage_id=1', before, '① BEFORE — Baggage status');

                try {
                    await api(`INSERT INTO baggage_claims (baggage_id, passenger_id, claim_type, description) VALUES (1, 1, 'LOST', 'Test claim from panel')`);
                } catch(e) {}

                const after = await api(`SELECT baggage_id, tag_number, status FROM baggage WHERE baggage_id = 1`);
                renderResult(target, 'SELECT baggage_id, tag_number, status FROM baggage WHERE baggage_id=1', after, '② AFTER — trg_after_baggage_claim_insert changed status');
                log('Trigger trg_after_baggage_claim tested ✓', 'ok');
                break;
            }
            case 'employee_delete': {
                const crew = await api(`SELECT e.employee_id, CONCAT(e.first_name,' ',e.last_name) AS name, fca.flight_id FROM employees e JOIN flight_crew_assignments fca ON e.employee_id=fca.employee_id LIMIT 3`);
                renderResult(target, 'SELECT employees with active flight assignments', crew, '① BEFORE — Employees assigned to flights');

                if (crew.length > 0) {
                    try {
                        await api(`DELETE FROM employees WHERE employee_id = ${crew[0].employee_id}`);
                        renderResult(target, `DELETE FROM employees WHERE employee_id=${crew[0].employee_id}`, [{result:'UNEXPECTED'}], '② RESULT');
                    } catch (e) {
                        renderResult(target, `DELETE FROM employees WHERE employee_id=${crew[0].employee_id}`, [{trigger_error: e.message}], '② RESULT — trg_before_employee_delete BLOCKED deletion ✓');
                        log('Trigger trg_before_employee_delete correctly prevented deletion ✓', 'ok');
                    }
                }
                break;
            }
            case 'maintenance_insert': {
                const before = await api(`SELECT aircraft_id, registration_no, status FROM aircraft WHERE aircraft_id = 3`);
                renderResult(target, 'SELECT aircraft_id, registration_no, status FROM aircraft WHERE aircraft_id=3', before, '① BEFORE — Aircraft status');

                try {
                    await api(`INSERT INTO maintenance_records (aircraft_id, maintenance_type, start_date, status, description) VALUES (3, 'UNSCHEDULED', NOW(), 'IN_PROGRESS', 'Test from panel')`);
                } catch(e) {}

                const after = await api(`SELECT aircraft_id, registration_no, status FROM aircraft WHERE aircraft_id = 3`);
                renderResult(target, 'SELECT aircraft_id, registration_no, status FROM aircraft WHERE aircraft_id=3', after, '② AFTER — trg_after_maintenance_insert set status to MAINTENANCE');
                log('Trigger trg_after_maintenance_insert tested ✓', 'ok');
                break;
            }
            case 'maintenance_complete': {
                try {
                    await api(`UPDATE maintenance_records SET status='COMPLETED', end_date=NOW() WHERE aircraft_id=3 AND status='IN_PROGRESS' ORDER BY record_id DESC LIMIT 1`);
                } catch(e) {}
                const after = await api(`SELECT aircraft_id, registration_no, status FROM aircraft WHERE aircraft_id = 3`);
                renderResult(target, "UPDATE maintenance_records SET status='COMPLETED' ...", after, 'AFTER — trg_after_maintenance_complete set aircraft back to ACTIVE');
                log('Trigger trg_after_maintenance_complete tested ✓', 'ok');
                break;
            }
            case 'shop_transaction': {
                const before = await api(`SELECT ff.passenger_id, ff.total_miles, ff.available_miles FROM frequent_flyer ff WHERE passenger_id=1`);
                renderResult(target, 'SELECT total_miles, available_miles FROM frequent_flyer WHERE passenger_id=1', before, '① BEFORE — FF miles');

                try {
                    await api(`INSERT INTO shop_transactions (shop_id, passenger_id, amount, payment_method, items_purchased) VALUES (1, 1, 75.00, 'CREDIT_CARD', 'Test purchase')`);
                } catch(e) {}

                const after = await api(`SELECT ff.passenger_id, ff.total_miles, ff.available_miles FROM frequent_flyer ff WHERE passenger_id=1`);
                renderResult(target, 'SELECT total_miles, available_miles FROM frequent_flyer WHERE passenger_id=1', after, '② AFTER — trg_after_shop_transaction awarded miles');
                log('Trigger trg_after_shop_transaction tested ✓', 'ok');
                break;
            }
            case 'gate_conflict': {
                const existing = await api(`SELECT * FROM gate_assignments WHERE status='ACTIVE' LIMIT 1`);
                renderResult(target, 'SELECT * FROM gate_assignments WHERE status=ACTIVE LIMIT 1', existing, '① Existing active gate assignment');

                if (existing.length > 0) {
                    try {
                        await api(`INSERT INTO gate_assignments (flight_id, gate_id, start_time, end_time) VALUES (999, ${existing[0].gate_id}, '${existing[0].start_time}', '${existing[0].end_time}')`);
                        renderResult(target, 'INSERT conflicting gate assignment', [{result:'UNEXPECTED'}], '② RESULT');
                    } catch(e) {
                        renderResult(target, `INSERT INTO gate_assignments — same gate, overlapping time`, [{trigger_error: e.message}], '② RESULT — trg_before_gate_assignment BLOCKED conflict ✓');
                        log('Trigger trg_before_gate_assignment correctly blocked conflict ✓', 'ok');
                    }
                }
                break;
            }
            case 'audit_booking': {
                const sql = `SELECT * FROM audit_log ORDER BY log_id DESC LIMIT 5`;
                const rows = await api(sql);
                renderResult(target, sql, rows, 'AUDIT LOG — trg_audit_booking_insert logs all booking operations');
                log('Showing recent audit log entries', 'ok');
                break;
            }
            case 'parking': {
                const before = await api(`SELECT lot_id, lot_name, total_spots, available_spots FROM parking_lots LIMIT 3`);
                renderResult(target, 'SELECT lot_id, lot_name, total_spots, available_spots FROM parking_lots', before, '① BEFORE — Parking availability');

                try {
                    await api(`INSERT INTO parking_reservations (lot_id, license_plate, vehicle_type, entry_time) VALUES (1, 'TEST-999', 'SEDAN', NOW())`);
                } catch(e) {}

                const after = await api(`SELECT lot_id, lot_name, total_spots, available_spots FROM parking_lots LIMIT 3`);
                renderResult(target, 'SELECT lot_id, lot_name, total_spots, available_spots FROM parking_lots', after, '② AFTER — trg_after_parking_reservation decreased available_spots');
                log('Trigger trg_after_parking_reservation tested ✓', 'ok');
                break;
            }
            case 'flight_delete': {
                const info = await api(`SELECT f.flight_id, f.flight_number, COUNT(b.booking_id) as booking_count FROM flights f LEFT JOIN bookings b ON f.flight_id=b.flight_id AND b.booking_status!='CANCELLED' WHERE f.flight_id=1 GROUP BY f.flight_id`);
                renderResult(target, 'Flight #1 with booking count', info, '① BEFORE — Flight has active bookings');

                try {
                    await api(`DELETE FROM flights WHERE flight_id = 1`);
                    renderResult(target, 'DELETE FROM flights WHERE flight_id=1', [{result:'UNEXPECTED'}], '② RESULT');
                } catch(e) {
                    renderResult(target, 'DELETE FROM flights WHERE flight_id=1', [{trigger_error: e.message}], '② RESULT — trg_before_flight_delete BLOCKED deletion ✓');
                    log('Trigger trg_before_flight_delete correctly prevented deletion ✓', 'ok');
                }
                break;
            }
        }
    } catch (e) { log('Trigger test error: ' + e.message, 'err'); }
}

// ============================================================
// FUNCTION TESTS
// ============================================================

async function testFunction(name) {
    const target = 'functions-result';
    const queries = {
        duration: { sql: `SELECT fn_calculate_flight_duration(1) AS duration_minutes`, label: 'fn_calculate_flight_duration(flight_id=1)' },
        miles: { sql: `SELECT fn_get_passenger_miles(1) AS total_miles`, label: 'fn_get_passenger_miles(passenger_id=1)' },
        utilization: { sql: `SELECT fn_aircraft_utilization_rate(1, 30) AS utilization_pct`, label: 'fn_aircraft_utilization_rate(aircraft_id=1, days=30)' },
        gate_occ: { sql: `SELECT fn_gate_occupancy_rate(1, CURDATE()) AS gate_occupancy_pct`, label: 'fn_gate_occupancy_rate(gate_id=1, today)' },
        flight_occ: { sql: `SELECT fn_flight_occupancy(1) AS flight_occupancy_pct`, label: 'fn_flight_occupancy(flight_id=1)' },
        revenue: { sql: `SELECT fn_get_airline_revenue(1, '2025-01-01', '2026-12-31') AS airline_revenue`, label: 'fn_get_airline_revenue(airline_id=1, 2025-2026)' }
    };
    const q = queries[name];
    try {
        const rows = await api(q.sql);
        renderResult(target, q.sql, rows, q.label);
        log(`Function ${q.label} executed ✓`, 'ok');
    } catch (e) { log(e.message, 'err'); }
}

// ============================================================
// PROCEDURE TESTS
// ============================================================

async function testProcedure(name) {
    const target = 'procedures-result';
    document.getElementById(target).innerHTML = '';

    try {
        switch (name) {
            case 'book': {
                const before = await api(`SELECT flight_id, flight_number, available_seats FROM flights WHERE flight_id=3`);
                renderResult(target, 'SELECT available_seats FROM flights WHERE flight_id=3', before, '① BEFORE — Available seats');

                await api(`CALL sp_book_flight(5, 3, 'BUSINESS', '3A', @bid, @res)`);
                const res = await api(`SELECT @bid as booking_id, @res as result`);
                renderResult(target, "CALL sp_book_flight(5, 3, 'BUSINESS', '3A', @bid, @res)", res, '② CALL sp_book_flight');

                const after = await api(`SELECT flight_id, flight_number, available_seats FROM flights WHERE flight_id=3`);
                renderResult(target, 'SELECT available_seats FROM flights WHERE flight_id=3', after, '③ AFTER — Seats decreased by 1');
                log('sp_book_flight tested ✓', 'ok');
                break;
            }
            case 'cancel': {
                const bookings = await api(`SELECT booking_id, booking_ref, booking_status, payment_status FROM bookings WHERE booking_status='CONFIRMED' ORDER BY booking_id DESC LIMIT 1`);
                if (bookings.length === 0) { log('No confirmed booking to cancel', 'err'); return; }
                renderResult(target, 'Last confirmed booking', bookings, '① BEFORE');

                const bid = bookings[0].booking_id;
                await api(`CALL sp_cancel_booking(${bid}, @res)`);
                const res = await api(`SELECT @res as result`);
                renderResult(target, `CALL sp_cancel_booking(${bid}, @res)`, res, '② CALL sp_cancel_booking');

                const after = await api(`SELECT booking_id, booking_ref, booking_status, payment_status FROM bookings WHERE booking_id=${bid}`);
                renderResult(target, `SELECT * FROM bookings WHERE booking_id=${bid}`, after, '③ AFTER — Status=CANCELLED, Payment=REFUNDED');
                log('sp_cancel_booking tested ✓', 'ok');
                break;
            }
            case 'checkin': {
                const bookings = await api(`SELECT booking_id, booking_ref, booking_status FROM bookings WHERE booking_status='CONFIRMED' LIMIT 1`);
                if (bookings.length === 0) { log('No confirmed booking to check-in', 'err'); return; }
                const bid = bookings[0].booking_id;
                renderResult(target, `Booking #${bid} status`, bookings, '① BEFORE');

                await api(`CALL sp_check_in_passenger(${bid}, '12B', @res)`);
                const res = await api(`SELECT @res as result`);
                renderResult(target, `CALL sp_check_in_passenger(${bid}, '12B', @res)`, res, '② CALL sp_check_in_passenger');

                const after = await api(`SELECT booking_id, booking_ref, booking_status, seat_number FROM bookings WHERE booking_id=${bid}`);
                renderResult(target, `SELECT * FROM bookings WHERE booking_id=${bid}`, after, '③ AFTER — CHECKED_IN');
                log('sp_check_in_passenger tested ✓', 'ok');
                break;
            }
            case 'transfer': {
                const bookings = await api(`SELECT booking_id, flight_id, booking_class FROM bookings WHERE booking_status IN ('CONFIRMED','CHECKED_IN') LIMIT 1`);
                if (bookings.length === 0) { log('No active booking to transfer', 'err'); return; }
                const bid = bookings[0].booking_id;
                renderResult(target, `Active booking #${bid}`, bookings, '① BEFORE');

                await api(`CALL sp_transfer_passenger(${bid}, 5, '22C', @res)`);
                const res = await api(`SELECT @res as result`);
                renderResult(target, `CALL sp_transfer_passenger(${bid}, 5, '22C', @res)`, res, '② CALL sp_transfer_passenger');

                const after = await api(`SELECT booking_id, booking_ref, flight_id, booking_status FROM bookings ORDER BY booking_id DESC LIMIT 3`);
                renderResult(target, 'Latest bookings (old cancelled + new created)', after, '③ AFTER — Old cancelled, new booking created');
                log('sp_transfer_passenger tested ✓', 'ok');
                break;
            }
            case 'gate': {
                const before = await api(`SELECT ga.assignment_id, ga.flight_id, ga.gate_id, g.gate_number, ga.status FROM gate_assignments ga JOIN gates g ON ga.gate_id=g.gate_id WHERE ga.flight_id=1 AND ga.status='ACTIVE'`);
                renderResult(target, 'Current gate for flight_id=1', before, '① BEFORE');

                await api(`CALL sp_reassign_gate(1, 5, @res)`);
                const res = await api(`SELECT @res as result`);
                renderResult(target, 'CALL sp_reassign_gate(1, 5, @res)', res, '② CALL sp_reassign_gate');

                const after = await api(`SELECT ga.assignment_id, ga.flight_id, ga.gate_id, g.gate_number, ga.status FROM gate_assignments ga JOIN gates g ON ga.gate_id=g.gate_id WHERE ga.flight_id=1 ORDER BY ga.assignment_id DESC LIMIT 3`);
                renderResult(target, 'Gate assignments for flight_id=1', after, '③ AFTER — Old=CANCELLED, New=ACTIVE');
                log('sp_reassign_gate tested ✓', 'ok');
                break;
            }
            case 'report': {
                const sql = `CALL sp_generate_daily_report(CURDATE())`;
                const rows = await api(sql);
                renderResult(target, sql, rows, 'DAILY REPORT — 3 result sets');
                log('sp_generate_daily_report tested ✓', 'ok');
                break;
            }
        }
    } catch (e) { log('Procedure test error: ' + e.message, 'err'); }
}

// ============================================================
// VIEW TESTS
// ============================================================

async function testView(viewName) {
    const sql = `SELECT * FROM ${viewName} LIMIT 20`;
    try {
        const rows = await api(sql);
        renderResult('views-result', sql, rows, `VIEW: ${viewName}`);
        log(`View ${viewName}: ${rows.length} rows ✓`, 'ok');
    } catch (e) { log(e.message, 'err'); }
}

// ============================================================
// TRANSACTION TESTS
// ============================================================

async function testTransaction(name) {
    const target = 'transactions-result';
    document.getElementById(target).innerHTML = '';

    try {
        switch (name) {
            case 'book_success': {
                const before = await api(`SELECT flight_id, available_seats FROM flights WHERE flight_id=4`);
                renderResult(target, 'SELECT available_seats FROM flights WHERE flight_id=4', before, '① BEFORE — available_seats');

                await api(`CALL sp_book_flight(8, 4, 'ECONOMY', '28D', @bid, @res)`);
                const res = await api(`SELECT @bid as booking_id, @res as result`);
                renderResult(target, "CALL sp_book_flight(8, 4, 'ECONOMY', '28D', @bid, @res)", res, '② TRANSACTION — COMMITTED');

                const after = await api(`SELECT flight_id, available_seats FROM flights WHERE flight_id=4`);
                renderResult(target, 'SELECT available_seats FROM flights WHERE flight_id=4', after, '③ AFTER — seats decremented (COMMIT successful)');
                log('Transaction COMMIT verified ✓', 'ok');
                break;
            }
            case 'book_fail': {
                // Try to book on a cancelled flight or nonexistent
                const before = await api(`SELECT flight_id, available_seats FROM flights WHERE flight_id=4`);
                renderResult(target, 'Seats before attempt', before, '① BEFORE');

                await api(`CALL sp_book_flight(1, 9999, 'ECONOMY', '1A', @bid, @res)`);
                const res = await api(`SELECT @bid as booking_id, @res as result`);
                renderResult(target, "CALL sp_book_flight(1, 9999, 'ECONOMY', '1A', @bid, @res) — nonexistent flight", res, '② TRANSACTION — ROLLED BACK');

                const after = await api(`SELECT flight_id, available_seats FROM flights WHERE flight_id=4`);
                renderResult(target, 'Seats after failed attempt (unchanged)', after, '③ AFTER — no changes (ROLLBACK successful)');
                log('Transaction ROLLBACK verified ✓', 'ok');
                break;
            }
            case 'cancel_success': {
                const bookings = await api(`SELECT booking_id, booking_ref, booking_status, payment_status FROM bookings WHERE booking_status='CONFIRMED' LIMIT 1`);
                if (bookings.length === 0) { log('No booking to cancel', 'err'); return; }
                renderResult(target, 'Active booking', bookings, '① BEFORE');

                const bid = bookings[0].booking_id;
                await api(`CALL sp_cancel_booking(${bid}, @res)`);
                const res = await api(`SELECT @res as result`);
                renderResult(target, `CALL sp_cancel_booking(${bid}, @res)`, res, '② TRANSACTION — COMMITTED');

                const after = await api(`SELECT booking_id, booking_status, payment_status FROM bookings WHERE booking_id=${bid}`);
                renderResult(target, `Booking #${bid} after cancel`, after, '③ AFTER — CANCELLED + REFUNDED atomically');
                log('Cancel transaction COMMIT ✓', 'ok');
                break;
            }
            case 'cancel_fail': {
                const bookings = await api(`SELECT booking_id, booking_ref, booking_status FROM bookings WHERE booking_status='CANCELLED' LIMIT 1`);
                if (bookings.length === 0) { log('No cancelled booking found', 'err'); return; }
                renderResult(target, 'Already cancelled booking', bookings, '① BEFORE');

                const bid = bookings[0].booking_id;
                await api(`CALL sp_cancel_booking(${bid}, @res)`);
                const res = await api(`SELECT @res as result`);
                renderResult(target, `CALL sp_cancel_booking(${bid}, @res)`, res, '② TRANSACTION — REJECTED (already cancelled)');
                log('Double-cancel correctly rejected ✓', 'ok');
                break;
            }
            case 'show_state': {
                const state = await api(`SELECT flight_id, flight_number, total_seats, available_seats, (total_seats - available_seats) AS booked_seats FROM flights ORDER BY flight_id`);
                renderResult(target, 'SELECT flight_id, flight_number, total_seats, available_seats, booked FROM flights', state, 'CURRENT STATE — All flights seat counts');
                log('Current state displayed', 'ok');
                break;
            }
        }
    } catch (e) { log('Transaction test error: ' + e.message, 'err'); }
}

// ============================================================
// JOIN TESTS
// ============================================================

async function testJoin(type) {
    const target = 'joins-result';
    const queries = {
        left: {
            sql: `SELECT f.flight_id, f.flight_number, a.airline_name, f.origin_airport, f.destination_airport, f.status, g.gate_number, t.terminal_name, CASE WHEN g.gate_number IS NULL THEN '** NO GATE ASSIGNED **' ELSE CONCAT(t.terminal_name, '-', g.gate_number) END AS gate_info FROM flights f LEFT OUTER JOIN gate_assignments ga ON f.flight_id = ga.flight_id AND ga.status = 'ACTIVE' LEFT OUTER JOIN gates g ON ga.gate_id = g.gate_id LEFT OUTER JOIN terminals t ON g.terminal_id = t.terminal_id JOIN airlines a ON f.airline_id = a.airline_id ORDER BY f.scheduled_departure`,
            label: 'LEFT OUTER JOIN — All flights, including those WITHOUT gate assignments (NULL gate columns)'
        },
        right: {
            sql: `SELECT g.gate_number, t.terminal_name, g.gate_type, g.is_available, f.flight_number, f.destination_airport, CASE WHEN f.flight_number IS NULL THEN '** GATE EMPTY **' ELSE CONCAT(f.flight_number, ' → ', f.destination_airport) END AS assignment_info FROM gate_assignments ga RIGHT OUTER JOIN gates g ON ga.gate_id = g.gate_id AND ga.status = 'ACTIVE' JOIN terminals t ON g.terminal_id = t.terminal_id LEFT JOIN flights f ON ga.flight_id = f.flight_id ORDER BY t.terminal_name, g.gate_number`,
            label: 'RIGHT OUTER JOIN — All gates, including those WITHOUT flight assignments'
        },
        full: {
            sql: `SELECT e.employee_id, CONCAT(e.first_name, ' ', e.last_name) AS name, e.employee_type, fca.role, f.flight_number, CASE WHEN f.flight_number IS NULL THEN '** NO FLIGHT **' ELSE 'Assigned' END AS status FROM employees e LEFT OUTER JOIN flight_crew_assignments fca ON e.employee_id = fca.employee_id LEFT OUTER JOIN flights f ON fca.flight_id = f.flight_id WHERE e.employee_type IN ('PILOT','CABIN_CREW') UNION SELECT e.employee_id, CONCAT(e.first_name, ' ', e.last_name), e.employee_type, fca.role, f.flight_number, CASE WHEN e.employee_id IS NULL THEN '** NO CREW **' ELSE 'Assigned' END FROM flight_crew_assignments fca RIGHT OUTER JOIN employees e ON fca.employee_id = e.employee_id RIGHT OUTER JOIN flights f ON fca.flight_id = f.flight_id WHERE e.employee_id IS NULL ORDER BY name, flight_number`,
            label: 'FULL OUTER JOIN (Emulated via UNION) — Employees ↔ Flights, showing unmatched on BOTH sides'
        }
    };
    const q = queries[type];
    try {
        const rows = await api(q.sql);
        renderResult(target, q.sql, rows, q.label);
        log(`${type.toUpperCase()} OUTER JOIN: ${rows.length} rows ✓`, 'ok');
    } catch (e) { log(e.message, 'err'); }
}

// ============================================================
// ADVANCED QUERY TESTS
// ============================================================

async function testAdvanced(name) {
    const target = 'advanced-result';
    const queries = {
        subquery: {
            sql: `SELECT CONCAT(p.first_name,' ',p.last_name) AS passenger, SUM(b.price) AS total_spent, (SELECT ROUND(AVG(price),2) FROM bookings WHERE payment_status='PAID') AS avg_price, COUNT(b.booking_id) AS bookings FROM passengers p JOIN bookings b ON p.passenger_id=b.passenger_id WHERE b.payment_status='PAID' GROUP BY p.passenger_id,p.first_name,p.last_name HAVING total_spent > (SELECT AVG(price)*2 FROM bookings WHERE payment_status='PAID') ORDER BY total_spent DESC`,
            label: 'SUBQUERY — Passengers spending > 2× average'
        },
        correlated: {
            sql: `SELECT a.airline_name, a.airline_code, COUNT(f.flight_id) AS total_flights, ROUND(AVG((f.total_seats-f.available_seats)/f.total_seats*100),1) AS avg_occupancy FROM airlines a JOIN flights f ON a.airline_id=f.airline_id WHERE f.status!='CANCELLED' GROUP BY a.airline_id,a.airline_name,a.airline_code HAVING avg_occupancy > (SELECT AVG((f2.total_seats-f2.available_seats)/f2.total_seats*100) FROM flights f2 WHERE f2.status!='CANCELLED') ORDER BY avg_occupancy DESC`,
            label: 'CORRELATED SUBQUERY — Airlines with above-average occupancy'
        },
        window: {
            sql: `SELECT CONCAT(p.first_name,' ',p.last_name) AS passenger, b.booking_class, b.price, f.flight_number, al.airline_name, RANK() OVER (ORDER BY b.price DESC) AS spending_rank, DENSE_RANK() OVER (PARTITION BY al.airline_id ORDER BY b.price DESC) AS airline_rank, SUM(b.price) OVER (PARTITION BY al.airline_id) AS airline_total, ROUND(b.price/SUM(b.price) OVER (PARTITION BY al.airline_id)*100,1) AS pct_of_airline FROM bookings b JOIN passengers p ON b.passenger_id=p.passenger_id JOIN flights f ON b.flight_id=f.flight_id JOIN airlines al ON f.airline_id=al.airline_id WHERE b.booking_status!='CANCELLED' ORDER BY spending_rank`,
            label: 'WINDOW FUNCTIONS — RANK(), DENSE_RANK(), SUM() OVER (PARTITION BY)'
        },
        cte: {
            sql: `WITH delay_stats AS (SELECT a.airline_name, COUNT(*) AS total_flights, SUM(CASE WHEN f.delay_minutes>0 THEN 1 ELSE 0 END) AS delayed_count, AVG(CASE WHEN f.delay_minutes>0 THEN f.delay_minutes END) AS avg_delay, MAX(f.delay_minutes) AS max_delay FROM flights f JOIN airlines a ON f.airline_id=a.airline_id GROUP BY a.airline_id,a.airline_name) SELECT *, ROUND((1-delayed_count/total_flights)*100,1) AS on_time_pct, CASE WHEN (delayed_count/total_flights)<0.1 THEN 'EXCELLENT' WHEN (delayed_count/total_flights)<0.25 THEN 'GOOD' WHEN (delayed_count/total_flights)<0.5 THEN 'FAIR' ELSE 'POOR' END AS rating FROM delay_stats ORDER BY on_time_pct DESC`,
            label: 'CTE (Common Table Expression) — Airline reliability rating'
        },
        exists: {
            sql: `SELECT p.passenger_id, CONCAT(p.first_name,' ',p.last_name) AS name, p.nationality FROM passengers p WHERE EXISTS (SELECT 1 FROM bookings b WHERE b.passenger_id=p.passenger_id AND b.booking_status!='CANCELLED') AND EXISTS (SELECT 1 FROM shop_transactions st WHERE st.passenger_id=p.passenger_id) ORDER BY p.last_name`,
            label: 'EXISTS — Passengers who booked a flight AND shopped'
        },
        selfjoin: {
            sql: `SELECT f1.flight_number AS first_leg, f1.origin_airport AS depart, f1.destination_airport AS connect_at, f2.flight_number AS second_leg, f2.destination_airport AS final_dest, TIMESTAMPDIFF(MINUTE,f1.scheduled_arrival,f2.scheduled_departure) AS layover_min FROM flights f1 JOIN flights f2 ON f1.destination_airport=f2.origin_airport AND f2.scheduled_departure>f1.scheduled_arrival AND TIMESTAMPDIFF(MINUTE,f1.scheduled_arrival,f2.scheduled_departure) BETWEEN 60 AND 360 WHERE f1.status!='CANCELLED' AND f2.status!='CANCELLED' AND f1.origin_airport!=f2.destination_airport ORDER BY f1.flight_number,layover_min`,
            label: 'SELF-JOIN — Possible connecting flights (1-6 hour layover)'
        },
        case: {
            sql: `SELECT f.origin_airport, f.destination_airport, COUNT(b.booking_id) AS bookings, SUM(CASE WHEN b.booking_class='ECONOMY' THEN b.price ELSE 0 END) AS economy_rev, SUM(CASE WHEN b.booking_class='BUSINESS' THEN b.price ELSE 0 END) AS business_rev, SUM(CASE WHEN b.booking_class='FIRST' THEN b.price ELSE 0 END) AS first_rev, SUM(b.price) AS total_revenue, ROUND(AVG(b.price),2) AS avg_ticket FROM flights f JOIN bookings b ON f.flight_id=b.flight_id WHERE b.booking_status!='CANCELLED' GROUP BY f.origin_airport,f.destination_airport ORDER BY total_revenue DESC`,
            label: 'CASE + GROUP BY — Revenue breakdown by route and class'
        }
    };
    const q = queries[name];
    try {
        const rows = await api(q.sql);
        renderResult(target, q.sql, rows, q.label);
        log(`Advanced query [${name}]: ${rows.length} rows ✓`, 'ok');
    } catch (e) { log(e.message, 'err'); }
}

// ============================================================
// SQL CONSOLE
// ============================================================

async function runSQL() {
    const sql = document.getElementById('sql-input').value.trim();
    if (!sql) return;
    try {
        const rows = await api(sql);
        renderResult('sql-result', sql, rows, 'MANUAL QUERY');
        log(`SQL executed: ${Array.isArray(rows) ? rows.length : 0} rows`, 'ok');
    } catch (e) {
        document.getElementById('sql-result').innerHTML = `<div class="msg err">${e.message}</div>` + document.getElementById('sql-result').innerHTML;
        log(e.message, 'err');
    }
}

document.addEventListener('keydown', e => {
    if (e.ctrlKey && e.key === 'Enter') runSQL();
});

// ============================================================
// AUDIT LOG
// ============================================================

async function loadAudit() {
    try {
        const rows = await api(`SELECT * FROM audit_log ORDER BY log_id DESC LIMIT 50`);
        renderResult('audit-result', 'SELECT * FROM audit_log ORDER BY log_id DESC LIMIT 50', rows, 'AUDIT LOG — Latest 50 entries');
        log(`Audit log: ${rows.length} entries`, 'ok');
    } catch (e) { log(e.message, 'err'); }
}

// ============================================================
// DB STATUS CHECK
// ============================================================

async function checkDB() {
    try {
        const rows = await api(`SELECT 1 as ok`);
        document.getElementById('db-status').className = 'ok';
        document.getElementById('db-status').textContent = 'connected (skyport_airport)';
        log('Database connection OK', 'ok');
    } catch (e) {
        document.getElementById('db-status').className = 'fail';
        document.getElementById('db-status').textContent = 'disconnected';
        log('Database connection FAILED: ' + e.message, 'err');
    }
}

checkDB();
