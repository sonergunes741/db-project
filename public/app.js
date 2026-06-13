// ============================================================
// SKYPORT AIRPORT DBMS — Frontend Application Logic
// ============================================================

const API = '';

// ============================================================
// NAVIGATION
// ============================================================

const moduleNames = {
    flights: '🛫 Flight Management',
    passengers: '👤 Passengers & Bookings',
    baggage: '🧳 Baggage & Cargo',
    employees: '👷 Employee Management',
    operations: '🏗️ Airport Operations',
    commercial: '🛍️ Commercial & Parking',
    admin: '⚙️ Admin Panel'
};

document.querySelectorAll('.nav-item').forEach(item => {
    item.addEventListener('click', () => {
        const module = item.dataset.module;
        document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
        item.classList.add('active');
        document.querySelectorAll('.module-panel').forEach(p => p.classList.remove('active'));
        document.getElementById(`module-${module}`).classList.add('active');
        document.getElementById('page-title').textContent = moduleNames[module] || module;
        loadModuleData(module);
    });
});

function loadModuleData(module) {
    switch(module) {
        case 'flights': loadFlights(); break;
        case 'passengers': loadPassengers(); loadBookings(); break;
        case 'baggage': loadBaggage(); loadCargo(); break;
        case 'employees': loadEmployees(); break;
        case 'operations': loadGates(); break;
        case 'commercial': loadShops(); break;
        case 'admin': loadAdminStats(); break;
    }
}

// ============================================================
// API HELPER
// ============================================================

async function api(url, options = {}) {
    try {
        const res = await fetch(API + url, {
            headers: { 'Content-Type': 'application/json' },
            ...options,
            body: options.body ? JSON.stringify(options.body) : undefined
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || 'API Error');
        return data;
    } catch (err) {
        toast(err.message, 'error');
        throw err;
    }
}

// ============================================================
// TOAST NOTIFICATIONS
// ============================================================

function toast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    const icons = { success: '✅', error: '❌', info: 'ℹ️', warning: '⚠️' };
    const t = document.createElement('div');
    t.className = `toast ${type}`;
    t.innerHTML = `<span>${icons[type] || ''}</span><span>${message}</span>`;
    container.appendChild(t);
    setTimeout(() => { t.style.opacity = '0'; setTimeout(() => t.remove(), 300); }, 4000);
}

// ============================================================
// MODAL
// ============================================================

function openModal(type) {
    const overlay = document.getElementById('modal-overlay');
    const title = document.getElementById('modal-title');
    const body = document.getElementById('modal-body');
    const footer = document.getElementById('modal-footer');
    overlay.classList.add('open');

    if (type === 'add-flight') {
        title.textContent = '✈️ Add New Flight';
        body.innerHTML = `
            <div class="form-row">
                <div class="form-group"><label>Flight Number</label><input class="form-control" id="f-number" placeholder="TK999"></div>
                <div class="form-group"><label>Airline ID</label><input class="form-control" id="f-airline" type="number" placeholder="1" value="1"></div>
            </div>
            <div class="form-row">
                <div class="form-group"><label>Origin</label><input class="form-control" id="f-origin" placeholder="SKP" value="SKP"></div>
                <div class="form-group"><label>Destination</label><input class="form-control" id="f-dest" placeholder="JFK"></div>
            </div>
            <div class="form-row">
                <div class="form-group"><label>Departure</label><input class="form-control" id="f-dep" type="datetime-local"></div>
                <div class="form-group"><label>Arrival</label><input class="form-control" id="f-arr" type="datetime-local"></div>
            </div>
            <div class="form-row">
                <div class="form-group"><label>Type</label><select class="form-control" id="f-type"><option value="INTERNATIONAL">International</option><option value="DOMESTIC">Domestic</option></select></div>
                <div class="form-group"><label>Aircraft ID</label><input class="form-control" id="f-aircraft" type="number" placeholder="1"></div>
            </div>
            <div class="form-row">
                <div class="form-group"><label>Total Seats</label><input class="form-control" id="f-seats" type="number" placeholder="189" value="189"></div>
                <div class="form-group"><label>Base Price ($)</label><input class="form-control" id="f-price" type="number" placeholder="350" value="350"></div>
            </div>`;
        footer.innerHTML = `<button class="btn btn-outline" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="addFlight()">Create Flight</button>`;
    } else if (type === 'add-passenger') {
        title.textContent = '👤 Add New Passenger';
        body.innerHTML = `
            <div class="form-row">
                <div class="form-group"><label>First Name</label><input class="form-control" id="p-first" placeholder="John"></div>
                <div class="form-group"><label>Last Name</label><input class="form-control" id="p-last" placeholder="Doe"></div>
            </div>
            <div class="form-row">
                <div class="form-group"><label>Email</label><input class="form-control" id="p-email" type="email" placeholder="john@email.com"></div>
                <div class="form-group"><label>Phone</label><input class="form-control" id="p-phone" placeholder="+1-555-0000"></div>
            </div>
            <div class="form-row">
                <div class="form-group"><label>Passport</label><input class="form-control" id="p-passport" placeholder="US12345678"></div>
                <div class="form-group"><label>Nationality</label><input class="form-control" id="p-nationality" placeholder="American"></div>
            </div>
            <div class="form-row">
                <div class="form-group"><label>Date of Birth</label><input class="form-control" id="p-dob" type="date"></div>
                <div class="form-group"><label>Gender</label><select class="form-control" id="p-gender"><option value="M">Male</option><option value="F">Female</option><option value="OTHER">Other</option></select></div>
            </div>`;
        footer.innerHTML = `<button class="btn btn-outline" onclick="closeModal()">Cancel</button><button class="btn btn-primary" onclick="addPassenger()">Add Passenger</button>`;
    }
}

function closeModal() {
    document.getElementById('modal-overlay').classList.remove('open');
}

// ============================================================
// STATUS BADGE HELPER
// ============================================================

function statusBadge(status) {
    if (!status) return '';
    const cls = status.toLowerCase().replace(/_/g, '-');
    return `<span class="badge-status ${cls}">${status.replace(/_/g, ' ')}</span>`;
}

function tierBadge(tier) {
    if (!tier) return '';
    return `<span class="badge-tier ${tier.toLowerCase()}">${tier}</span>`;
}

function formatDate(d) {
    if (!d) return '—';
    const dt = new Date(d);
    return dt.toLocaleDateString('en-GB', { day: '2-digit', month: 'short' }) + ' ' + dt.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
}

function formatMoney(v) {
    return v != null ? '$' + Number(v).toLocaleString('en-US', { minimumFractionDigits: 2 }) : '—';
}

// ============================================================
// MODULE 1: FLIGHTS
// ============================================================

async function loadFlights() {
    try {
        const flights = await api('/api/flights');
        const tbody = document.getElementById('flights-tbody');

        const stats = document.getElementById('flight-stats');
        const scheduled = flights.filter(f => f.status === 'SCHEDULED').length;
        const delayed = flights.filter(f => f.status === 'DELAYED').length;
        const inAir = flights.filter(f => f.status === 'IN_AIR' || f.status === 'DEPARTED').length;
        const arrived = flights.filter(f => f.status === 'ARRIVED').length;
        stats.innerHTML = `
            <div class="stat-card blue"><div class="stat-icon">📋</div><div class="stat-value">${flights.length}</div><div class="stat-label">Total Flights</div></div>
            <div class="stat-card cyan"><div class="stat-icon">⏳</div><div class="stat-value">${scheduled}</div><div class="stat-label">Scheduled</div></div>
            <div class="stat-card yellow"><div class="stat-icon">⚠️</div><div class="stat-value">${delayed}</div><div class="stat-label">Delayed</div></div>
            <div class="stat-card purple"><div class="stat-icon">✈️</div><div class="stat-value">${inAir}</div><div class="stat-label">In Air</div></div>
            <div class="stat-card green"><div class="stat-icon">🛬</div><div class="stat-value">${arrived}</div><div class="stat-label">Arrived</div></div>
        `;

        tbody.innerHTML = flights.map(f => `
            <tr>
                <td><strong class="text-blue">${f.flight_number}</strong></td>
                <td>${f.airline_name}</td>
                <td>${f.origin_airport} → ${f.destination_airport}</td>
                <td>${formatDate(f.scheduled_departure)}</td>
                <td class="text-muted">${f.aircraft_model || '—'}</td>
                <td>${f.gate_number ? `${f.terminal_name} - ${f.gate_number}` : '<span class="text-muted">—</span>'}</td>
                <td><span class="text-mono">${f.occupancy_pct || 0}%</span></td>
                <td>${statusBadge(f.status)}</td>
                <td>
                    <div class="btn-group">
                        <button class="btn btn-ghost btn-xs" onclick="loadFlightHistory(${f.flight_id})" title="History">📜</button>
                        <button class="btn btn-ghost btn-xs" onclick="deleteFlight(${f.flight_id})" title="Delete">🗑️</button>
                    </div>
                </td>
            </tr>
        `).join('');
    } catch (e) { console.error(e); }
}

async function addFlight() {
    try {
        const data = {
            flight_number: document.getElementById('f-number').value,
            airline_id: +document.getElementById('f-airline').value,
            aircraft_id: +document.getElementById('f-aircraft').value || null,
            origin_airport: document.getElementById('f-origin').value,
            destination_airport: document.getElementById('f-dest').value,
            scheduled_departure: document.getElementById('f-dep').value,
            scheduled_arrival: document.getElementById('f-arr').value,
            flight_type: document.getElementById('f-type').value,
            total_seats: +document.getElementById('f-seats').value,
            base_price: +document.getElementById('f-price').value
        };
        const res = await api('/api/flights', { method: 'POST', body: data });
        toast(res.message, 'success');
        closeModal();
        loadFlights();
    } catch (e) {}
}

async function shortcutUpdateFlightStatus(id, status, delay, reason) {
    try {
        const res = await api(`/api/flights/${id}/status`, {
            method: 'PUT', body: { status, delay_minutes: delay || 0, delay_reason: reason || null }
        });
        toast(res.message, 'success');
        loadFlights();
    } catch (e) {}
}

async function deleteFlight(id) {
    if (!confirm('Delete this flight?')) return;
    try {
        const res = await api(`/api/flights/${id}`, { method: 'DELETE' });
        toast(res.message, 'success');
        loadFlights();
    } catch (e) {}
}

async function loadFlightHistory(flightId) {
    try {
        const history = await api(`/api/flights/${flightId}/history`);
        const panel = document.getElementById('flight-history-panel');
        panel.innerHTML = `
            <div class="card mt-2">
                <div class="card-header"><h3>📜 Flight #${flightId} Status History</h3></div>
                <div class="card-body">
                    ${history.length ? `<table class="data-table">
                        <thead><tr><th>Time</th><th>Old Status</th><th>New Status</th><th>Changed By</th><th>Notes</th></tr></thead>
                        <tbody>${history.map(h => `
                            <tr>
                                <td>${formatDate(h.changed_at)}</td>
                                <td>${h.old_status ? statusBadge(h.old_status) : '—'}</td>
                                <td>${statusBadge(h.new_status)}</td>
                                <td>${h.changed_by}</td>
                                <td class="text-muted" style="white-space:normal;max-width:300px">${h.notes || ''}</td>
                            </tr>`).join('')}</tbody>
                    </table>` : '<div class="empty-state"><div class="empty-icon">📭</div>No status changes recorded</div>'}
                </div>
            </div>`;
        toast(`Loaded ${history.length} history entries`, 'info');
    } catch (e) {}
}

// ============================================================
// MODULE 2: PASSENGERS & BOOKINGS
// ============================================================

function switchPassengerTab(tab) {
    document.querySelectorAll('#module-passengers .tab').forEach(t => t.classList.remove('active'));
    event.target.classList.add('active');
    ['passengers', 'bookings', 'itinerary', 'frequent'].forEach(t => {
        const el = document.getElementById(`${t}-content`);
        if (el) el.style.display = t === tab ? 'block' : 'none';
    });
    if (tab === 'bookings') loadBookings();
    if (tab === 'frequent') loadFrequentFlyer();
}

async function loadPassengers() {
    try {
        const passengers = await api('/api/passengers');
        document.getElementById('passengers-tbody').innerHTML = passengers.map(p => `
            <tr>
                <td>${p.passenger_id}</td>
                <td><strong>${p.first_name} ${p.last_name}</strong></td>
                <td class="text-muted">${p.email || ''}</td>
                <td class="text-mono">${p.passport_number || ''}</td>
                <td>${p.nationality || ''}</td>
                <td class="text-muted">${p.phone || ''}</td>
            </tr>
        `).join('');

        document.getElementById('passenger-stats').innerHTML = `
            <div class="stat-card blue"><div class="stat-icon">👤</div><div class="stat-value">${passengers.length}</div><div class="stat-label">Total Passengers</div></div>
            <div class="stat-card green"><div class="stat-icon">🌍</div><div class="stat-value">${new Set(passengers.map(p=>p.nationality).filter(Boolean)).size}</div><div class="stat-label">Nationalities</div></div>
        `;
    } catch (e) {}
}

async function searchPassengers(term) {
    if (term.length < 2) { loadPassengers(); return; }
    try {
        const passengers = await api(`/api/passengers/search/${encodeURIComponent(term)}`);
        document.getElementById('passengers-tbody').innerHTML = passengers.map(p => `
            <tr>
                <td>${p.passenger_id}</td>
                <td><strong>${p.first_name} ${p.last_name}</strong></td>
                <td class="text-muted">${p.email || ''}</td>
                <td class="text-mono">${p.passport_number || ''}</td>
                <td>${p.nationality || ''}</td>
                <td class="text-muted">${p.phone || ''}</td>
            </tr>
        `).join('');
    } catch (e) {}
}

async function addPassenger() {
    try {
        const data = {
            first_name: document.getElementById('p-first').value,
            last_name: document.getElementById('p-last').value,
            email: document.getElementById('p-email').value,
            phone: document.getElementById('p-phone').value,
            passport_number: document.getElementById('p-passport').value,
            nationality: document.getElementById('p-nationality').value,
            date_of_birth: document.getElementById('p-dob').value,
            gender: document.getElementById('p-gender').value
        };
        const res = await api('/api/passengers', { method: 'POST', body: data });
        toast(res.message, 'success');
        closeModal();
        loadPassengers();
    } catch (e) {}
}

async function loadBookings() {
    try {
        const bookings = await api('/api/bookings');
        document.getElementById('bookings-tbody').innerHTML = bookings.map(b => `
            <tr>
                <td>${b.booking_id}</td>
                <td class="text-mono text-blue">${b.booking_ref}</td>
                <td>${b.passenger_name}</td>
                <td><strong>${b.flight_number}</strong></td>
                <td>${b.origin_airport} → ${b.destination_airport}</td>
                <td>${b.booking_class}</td>
                <td class="text-mono">${b.seat_number || '—'}</td>
                <td>${formatMoney(b.price)}</td>
                <td>${statusBadge(b.booking_status)}</td>
                <td>${statusBadge(b.payment_status)}</td>
                <td>
                    <div class="btn-group">
                        ${b.booking_status === 'CONFIRMED' ? `<button class="btn btn-success btn-xs" onclick="shortcutCheckIn(${b.booking_id})">Check-in</button>` : ''}
                        ${b.booking_status !== 'CANCELLED' ? `<button class="btn btn-danger btn-xs" onclick="shortcutCancelBooking(${b.booking_id})">Cancel</button>` : ''}
                    </div>
                </td>
            </tr>
        `).join('');

        // Update stats
        const stats = document.getElementById('passenger-stats');
        const confirmed = bookings.filter(b => b.booking_status === 'CONFIRMED').length;
        const totalRev = bookings.filter(b => b.payment_status === 'PAID').reduce((s,b) => s + Number(b.price), 0);
        stats.innerHTML += `
            <div class="stat-card cyan"><div class="stat-icon">📝</div><div class="stat-value">${bookings.length}</div><div class="stat-label">Total Bookings</div></div>
            <div class="stat-card yellow"><div class="stat-icon">💰</div><div class="stat-value">${formatMoney(totalRev)}</div><div class="stat-label">Total Revenue</div></div>
        `;
    } catch (e) {}
}

async function shortcutBookFlight(passengerId, flightId, cls, seat) {
    try {
        const res = await api('/api/bookings/book', {
            method: 'POST', body: { passenger_id: passengerId, flight_id: flightId, booking_class: cls, seat_number: seat }
        });
        toast(res.result, res.success ? 'success' : 'error');
        loadBookings(); loadFlights();
    } catch (e) {}
}

async function shortcutCheckIn(bookingId) {
    try {
        const res = await api(`/api/bookings/${bookingId}/checkin`, { method: 'POST', body: {} });
        toast(res.result, res.success ? 'success' : 'error');
        loadBookings();
    } catch (e) {}
}

async function shortcutCancelBooking(bookingId) {
    try {
        const res = await api(`/api/bookings/${bookingId}/cancel`, { method: 'POST' });
        toast(res.result, res.success ? 'success' : 'error');
        loadBookings(); loadFlights();
    } catch (e) {}
}

async function shortcutTransfer(bookingId, newFlightId, newSeat) {
    try {
        const res = await api(`/api/bookings/${bookingId}/transfer`, {
            method: 'POST', body: { new_flight_id: newFlightId, new_seat: newSeat }
        });
        toast(res.result, res.success ? 'success' : 'error');
        loadBookings(); loadFlights();
    } catch (e) {}
}

async function loadPassengerItinerary(passengerId) {
    try {
        const itinerary = await api(`/api/passengers/${passengerId}/itinerary`);
        const content = document.getElementById('itinerary-content');
        content.innerHTML = `<div class="card"><div class="card-header"><h3>🗺️ Itinerary for ${itinerary[0]?.passenger_name || 'Passenger #'+passengerId}</h3></div>
            <div class="card-body">
                <table class="data-table"><thead><tr>
                    <th>Ref</th><th>Flight</th><th>Route</th><th>Departure</th><th>Class</th><th>Seat</th><th>Gate</th><th>Boarding</th><th>Status</th>
                </tr></thead><tbody>${itinerary.map(i => `<tr>
                    <td class="text-mono text-blue">${i.booking_ref}</td>
                    <td><strong>${i.flight_number}</strong></td>
                    <td>${i.origin_airport} → ${i.destination_airport}</td>
                    <td>${formatDate(i.scheduled_departure)}</td>
                    <td>${i.booking_class}</td>
                    <td class="text-mono">${i.seat_number || '—'}</td>
                    <td>${i.gate_number ? `${i.terminal_name}-${i.gate_number}` : '—'}</td>
                    <td>${i.boarding_group || '—'}</td>
                    <td>${statusBadge(i.booking_status)}</td>
                </tr>`).join('')}</tbody></table>
            </div></div>`;
        // switch to itinerary tab
        document.querySelectorAll('#module-passengers .tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('#module-passengers .tab')[2].classList.add('active');
        ['passengers', 'bookings', 'itinerary', 'frequent'].forEach(t => {
            const el = document.getElementById(`${t}-content`);
            if (el) el.style.display = t === 'itinerary' ? 'block' : 'none';
        });
    } catch (e) {}
}

async function loadFrequentFlyer() {
    try {
        const ff = await api('/api/frequent-flyer');
        document.getElementById('frequent-content').innerHTML = `<div class="card"><div class="card-header"><h3>🎖️ Frequent Flyer Program</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr>
                <th>Passenger</th><th>Airline</th><th>FF Number</th><th>Tier</th><th>Total Miles</th><th>Available Miles</th><th>Last Activity</th>
            </tr></thead><tbody>${ff.map(f => `<tr>
                <td><strong>${f.passenger_name}</strong></td>
                <td>${f.airline_name}</td>
                <td class="text-mono">${f.ff_number}</td>
                <td>${tierBadge(f.tier)}</td>
                <td class="text-mono">${Number(f.total_miles).toLocaleString()}</td>
                <td class="text-mono text-green">${Number(f.available_miles).toLocaleString()}</td>
                <td class="text-muted">${f.last_activity || '—'}</td>
            </tr>`).join('')}</tbody></table></div></div>`;
    } catch (e) {}
}

// ============================================================
// MODULE 3: BAGGAGE & CARGO
// ============================================================

function switchBaggageTab(tab) {
    document.querySelectorAll('#module-baggage .tab').forEach(t => t.classList.remove('active'));
    event.target.classList.add('active');
    document.getElementById('baggage-tracking-content').style.display = tab === 'tracking' ? 'block' : 'none';
    document.getElementById('cargo-content').style.display = tab === 'cargo' ? 'block' : 'none';
    if (tab === 'cargo') loadCargo();
}

async function loadBaggage() {
    try {
        const baggage = await api('/api/baggage');
        document.getElementById('baggage-tbody').innerHTML = baggage.map(b => `
            <tr>
                <td>${b.baggage_id}</td>
                <td class="text-mono">${b.tag_number}</td>
                <td>${b.passenger_name}</td>
                <td><strong>${b.flight_number}</strong></td>
                <td>${b.origin_airport} → ${b.destination_airport}</td>
                <td>${b.weight_kg} kg</td>
                <td>${b.baggage_type}</td>
                <td>${statusBadge(b.baggage_status)}</td>
                <td>${b.claim_id ? `<span class="badge-status ${b.claim_status?.toLowerCase()}">${b.claim_type}: ${b.claim_status}</span>` : '<span class="text-muted">None</span>'}</td>
            </tr>
        `).join('');
    } catch (e) {}
}

async function loadCargo() {
    try {
        const cargo = await api('/api/cargo');
        document.getElementById('cargo-tbody').innerHTML = cargo.map(c => `
            <tr>
                <td>${c.shipment_id}</td>
                <td><strong>${c.flight_number}</strong></td>
                <td>${c.origin_airport} → ${c.destination_airport}</td>
                <td>${c.shipper_name}</td>
                <td>${c.receiver_name}</td>
                <td>${c.shipment_type}</td>
                <td>${c.weight_kg} kg</td>
                <td>${formatMoney(c.price)}</td>
                <td>${statusBadge(c.status)}</td>
            </tr>
        `).join('');
    } catch (e) {}
}

async function shortcutAddBaggage(bookingId) {
    const tag = 'BG' + String(Date.now()).slice(-8);
    try {
        const res = await api('/api/baggage', { method: 'POST', body: { booking_id: bookingId, tag_number: tag, weight_kg: 22.5, baggage_type: 'CHECKED' } });
        toast(res.message + ` (Tag: ${tag})`, 'success');
        loadBaggage();
    } catch (e) {}
}

async function shortcutUpdateBaggage(id, status) {
    try {
        const res = await api(`/api/baggage/${id}/status`, { method: 'PUT', body: { status } });
        toast(res.message, 'success');
        loadBaggage();
    } catch (e) {}
}

async function shortcutFileClaim(baggageId, passengerId, claimType) {
    try {
        const res = await api('/api/baggage-claims', { method: 'POST', body: { baggage_id: baggageId, passenger_id: passengerId, claim_type: claimType, description: 'Filed via admin panel shortcut' } });
        toast(res.message, 'success');
        loadBaggage();
    } catch (e) {}
}

// ============================================================
// MODULE 4: EMPLOYEES
// ============================================================

function switchEmployeeTab(tab) {
    document.querySelectorAll('#module-employees .tab').forEach(t => t.classList.remove('active'));
    event.target.classList.add('active');
    document.getElementById('employee-directory-content').style.display = tab === 'directory' ? 'block' : 'none';
    document.getElementById('crew-schedule-content').style.display = tab === 'crew' ? 'block' : 'none';
    if (tab === 'crew') loadCrewSchedule();
}

async function loadEmployees() {
    try {
        const employees = await api('/api/employees');
        const typeColors = { PILOT: 'text-blue', CABIN_CREW: 'text-green', GROUND_STAFF: 'text-yellow', SECURITY: 'text-red' };
        document.getElementById('employees-tbody').innerHTML = employees.map(e => `
            <tr>
                <td>${e.employee_id}</td>
                <td><strong>${e.full_name}</strong></td>
                <td><span class="${typeColors[e.employee_type] || ''}">${e.employee_type}</span></td>
                <td class="text-muted">${e.email}</td>
                <td>${e.airline_name || '<span class="text-muted">Airport</span>'}</td>
                <td class="text-muted">${e.hire_date || ''}</td>
                <td class="text-mono">${formatMoney(e.salary)}</td>
                <td class="text-muted" style="white-space:normal;max-width:250px;font-size:11px">${e.specialization_details || ''}</td>
                <td>${e.is_active ? '✅' : '❌'}</td>
            </tr>
        `).join('');

        const pilots = employees.filter(e => e.employee_type === 'PILOT').length;
        const crew = employees.filter(e => e.employee_type === 'CABIN_CREW').length;
        const ground = employees.filter(e => e.employee_type === 'GROUND_STAFF').length;
        const security = employees.filter(e => e.employee_type === 'SECURITY').length;
        document.getElementById('employee-stats').innerHTML = `
            <div class="stat-card blue"><div class="stat-icon">👨‍✈️</div><div class="stat-value">${pilots}</div><div class="stat-label">Pilots</div></div>
            <div class="stat-card green"><div class="stat-icon">💁</div><div class="stat-value">${crew}</div><div class="stat-label">Cabin Crew</div></div>
            <div class="stat-card yellow"><div class="stat-icon">🔧</div><div class="stat-value">${ground}</div><div class="stat-label">Ground Staff</div></div>
            <div class="stat-card red"><div class="stat-icon">🛡️</div><div class="stat-value">${security}</div><div class="stat-label">Security</div></div>
        `;
    } catch (e) {}
}

async function loadCrewSchedule() {
    try {
        const schedule = await api('/api/crew-schedule');
        document.getElementById('crew-schedule-content').innerHTML = `<div class="card"><div class="card-header"><h3>📅 Crew Flight Schedule</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr>
                <th>Crew Member</th><th>Type</th><th>Role</th><th>Flight</th><th>Route</th><th>Departure</th><th>Arrival</th><th>Status</th>
            </tr></thead><tbody>${schedule.map(s => `<tr>
                <td><strong>${s.crew_name}</strong></td>
                <td>${s.employee_type}</td>
                <td>${s.role}</td>
                <td class="text-blue">${s.flight_number}</td>
                <td>${s.origin_airport} → ${s.destination_airport}</td>
                <td>${formatDate(s.scheduled_departure)}</td>
                <td>${formatDate(s.scheduled_arrival)}</td>
                <td>${statusBadge(s.flight_status)}</td>
            </tr>`).join('')}</tbody></table></div></div>`;
    } catch (e) {}
}

// ============================================================
// MODULE 5: OPERATIONS
// ============================================================

function switchOpsTab(tab) {
    document.querySelectorAll('#module-operations .tab').forEach(t => t.classList.remove('active'));
    event.target.classList.add('active');
    ['gates','terminals','runways','maintenance','aircraft','airline-stats'].forEach(t => {
        const el = document.getElementById(`ops-${t}-content`);
        if (el) el.style.display = t === tab ? 'block' : 'none';
    });
    if (tab === 'terminals') loadTerminals();
    if (tab === 'runways') loadRunways();
    if (tab === 'maintenance') loadMaintenance();
    if (tab === 'aircraft') loadAircraft();
    if (tab === 'airline-stats') loadAirlineStats();
}

async function loadGates() {
    try {
        const gates = await api('/api/gates');
        document.getElementById('gates-tbody').innerHTML = gates.map(g => `
            <tr>
                <td><strong>${g.gate_number}</strong></td>
                <td>${g.terminal_name}</td>
                <td>${g.gate_type}</td>
                <td>${g.is_available ? '<span class="text-green">✅ Available</span>' : '<span class="text-red">🔴 Occupied</span>'}</td>
                <td>${g.flight_number ? `<span class="text-blue">${g.flight_number}</span>` : '—'}</td>
                <td>${g.destination_airport || '—'}</td>
                <td class="text-muted">${g.start_time && g.end_time ? formatDate(g.start_time) + ' - ' + formatDate(g.end_time) : '—'}</td>
            </tr>
        `).join('');
    } catch (e) {}
}

async function loadTerminals() {
    try {
        const terminals = await api('/api/terminals');
        document.getElementById('ops-terminals-content').innerHTML = `<div class="card"><div class="card-header"><h3>🏢 Terminals</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr>
                <th>Terminal</th><th>Floors</th><th>Lounge</th><th>Duty Free</th><th>Status</th>
            </tr></thead><tbody>${terminals.map(t => `<tr>
                <td><strong>${t.terminal_name}</strong></td>
                <td>${t.floor_count}</td>
                <td>${t.has_lounge ? '✅' : '❌'}</td>
                <td>${t.has_duty_free ? '✅' : '❌'}</td>
                <td>${statusBadge(t.status)}</td>
            </tr>`).join('')}</tbody></table></div></div>`;
    } catch (e) {}
}

async function loadRunways() {
    try {
        const runways = await api('/api/runways');
        document.getElementById('ops-runways-content').innerHTML = `<div class="card"><div class="card-header"><h3>🛤️ Runways</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr>
                <th>Code</th><th>Length (m)</th><th>Width (m)</th><th>Surface</th><th>Active</th><th>Status</th>
            </tr></thead><tbody>${runways.map(r => `<tr>
                <td><strong>${r.runway_code}</strong></td>
                <td>${r.length_meters.toLocaleString()}</td>
                <td>${r.width_meters}</td>
                <td>${r.surface_type}</td>
                <td>${r.is_active ? '✅' : '❌'}</td>
                <td>${statusBadge(r.status)}</td>
            </tr>`).join('')}</tbody></table></div></div>`;
    } catch (e) {}
}

async function loadMaintenance() {
    try {
        const records = await api('/api/maintenance');
        document.getElementById('ops-maintenance-content').innerHTML = `<div class="card"><div class="card-header"><h3>🔧 Maintenance Records</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr>
                <th>Aircraft</th><th>Type</th><th>Airline</th><th>Maint. Type</th><th>Start</th><th>End</th><th>Technician</th><th>Cost</th><th>Status</th>
            </tr></thead><tbody>${records.map(m => `<tr>
                <td><strong>${m.registration_no}</strong></td>
                <td>${m.manufacturer} ${m.model}</td>
                <td>${m.airline_name}</td>
                <td>${m.maintenance_type}</td>
                <td>${formatDate(m.start_date)}</td>
                <td>${m.end_date ? formatDate(m.end_date) : '—'}</td>
                <td>${m.technician_name || '—'}</td>
                <td>${formatMoney(m.cost)}</td>
                <td>${statusBadge(m.status)}</td>
            </tr>`).join('')}</tbody></table></div></div>`;
    } catch (e) {}
}

async function loadAircraft() {
    try {
        const aircraft = await api('/api/aircraft');
        document.getElementById('ops-aircraft-content').innerHTML = `<div class="card"><div class="card-header"><h3>🛩️ Fleet</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr>
                <th>Registration</th><th>Airline</th><th>Type</th><th>Model</th><th>Year</th><th>Flight Hours</th><th>Status</th><th>Next Maint.</th>
            </tr></thead><tbody>${aircraft.map(a => `<tr>
                <td class="text-mono"><strong>${a.registration_no}</strong></td>
                <td>${a.airline_name}</td>
                <td>${a.type_code}</td>
                <td>${a.manufacturer} ${a.model}</td>
                <td>${a.manufacture_year}</td>
                <td class="text-mono">${Number(a.total_flight_hours).toLocaleString()}</td>
                <td>${statusBadge(a.status)}</td>
                <td class="text-muted">${a.next_maintenance || '—'}</td>
            </tr>`).join('')}</tbody></table></div></div>`;
    } catch (e) {}
}

async function loadAirlineStats() {
    try {
        const stats = await api('/api/airlines/stats');
        document.getElementById('ops-airline-stats-content').innerHTML = `<div class="card"><div class="card-header"><h3>📊 Airline Statistics (View)</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr>
                <th>Airline</th><th>Code</th><th>Alliance</th><th>Flights</th><th>Fleet</th><th>Bookings</th><th>Revenue</th><th>Delayed</th><th>Avg Delay</th><th>Avg Occupancy</th>
            </tr></thead><tbody>${stats.map(s => `<tr>
                <td><strong>${s.airline_name}</strong></td>
                <td class="text-mono">${s.airline_code}</td>
                <td>${s.alliance}</td>
                <td>${s.total_flights}</td>
                <td>${s.fleet_size}</td>
                <td>${s.total_bookings}</td>
                <td class="text-green">${formatMoney(s.total_revenue)}</td>
                <td>${s.delayed_flights > 0 ? `<span class="text-red">${s.delayed_flights}</span>` : '0'}</td>
                <td>${s.avg_delay_min ? s.avg_delay_min + ' min' : '—'}</td>
                <td class="text-mono">${s.avg_occupancy_pct || 0}%</td>
            </tr>`).join('')}</tbody></table></div></div>`;
    } catch (e) {}
}

async function shortcutReassignGate(flightId, newGateId) {
    try {
        const res = await api('/api/gates/reassign', { method: 'POST', body: { flight_id: flightId, new_gate_id: newGateId } });
        toast(res.result, res.success ? 'success' : 'error');
        loadGates(); loadFlights();
    } catch (e) {}
}

// ============================================================
// MODULE 6: COMMERCIAL & PARKING
// ============================================================

function switchCommTab(tab) {
    document.querySelectorAll('#module-commercial .tab').forEach(t => t.classList.remove('active'));
    event.target.classList.add('active');
    ['shops','transactions','parking'].forEach(t => {
        const el = document.getElementById(`comm-${t}-content`);
        if (el) el.style.display = t === tab ? 'block' : 'none';
    });
    if (tab === 'transactions') loadShopTransactions();
    if (tab === 'parking') loadParking();
}

async function loadShops() {
    try {
        const shops = await api('/api/shops');
        document.getElementById('shops-tbody').innerHTML = shops.map(s => `
            <tr>
                <td><strong>${s.shop_name}</strong></td>
                <td>${s.shop_type}</td>
                <td>${s.terminal_name}</td>
                <td>${s.floor_number}</td>
                <td>${s.opening_time} - ${s.closing_time}</td>
                <td>${formatMoney(s.monthly_rent)}</td>
                <td>${s.is_active ? '✅' : '❌'}</td>
            </tr>
        `).join('');
    } catch (e) {}
}

async function loadShopTransactions() {
    try {
        const txns = await api('/api/shop-transactions');
        document.getElementById('comm-transactions-content').innerHTML = `<div class="card"><div class="card-header"><h3>💳 Shop Transactions</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr>
                <th>ID</th><th>Shop</th><th>Customer</th><th>Amount</th><th>Payment</th><th>Items</th><th>Time</th>
            </tr></thead><tbody>${txns.map(t => `<tr>
                <td>${t.transaction_id}</td>
                <td><strong>${t.shop_name}</strong></td>
                <td>${t.customer_name || '<span class="text-muted">Anonymous</span>'}</td>
                <td class="text-green">${formatMoney(t.amount)}</td>
                <td>${t.payment_method}</td>
                <td class="text-muted" style="max-width:250px;white-space:normal;font-size:12px">${t.items_purchased || ''}</td>
                <td class="text-muted">${formatDate(t.transaction_time)}</td>
            </tr>`).join('')}</tbody></table></div></div>`;
    } catch (e) {}
}

async function loadParking() {
    try {
        const lots = await api('/api/parking');
        document.getElementById('comm-parking-content').innerHTML = `<div class="card"><div class="card-header"><h3>🅿️ Parking Availability</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr>
                <th>Lot</th><th>Type</th><th>Terminal</th><th>Total</th><th>Available</th><th>Occupied</th><th>Occupancy</th><th>Rate/hr</th><th>Daily Max</th><th>Covered</th>
            </tr></thead><tbody>${lots.map(p => `<tr>
                <td><strong>${p.lot_name}</strong></td>
                <td>${p.lot_type}</td>
                <td>${p.terminal_name || '—'}</td>
                <td>${p.total_spots}</td>
                <td class="text-green">${p.available_spots}</td>
                <td>${p.occupied_spots}</td>
                <td class="text-mono">${p.occupancy_pct}%</td>
                <td>${formatMoney(p.hourly_rate)}</td>
                <td>${formatMoney(p.daily_max)}</td>
                <td>${p.is_covered ? '✅' : '❌'}</td>
            </tr>`).join('')}</tbody></table></div></div>`;
    } catch (e) {}
}

// ============================================================
// MODULE 7: ADMIN PANEL
// ============================================================

function switchAdminTab(tab) {
    document.querySelectorAll('#module-admin .tab').forEach(t => t.classList.remove('active'));
    event.target.classList.add('active');
    ['sql','audit','dbinfo'].forEach(t => {
        const el = document.getElementById(`admin-${t}-content`);
        if (el) el.style.display = t === tab ? 'block' : 'none';
    });
    if (tab === 'audit') loadAuditLog();
    if (tab === 'dbinfo') loadDBInfo();
}

async function loadAdminStats() {
    try {
        const stats = await api('/api/admin/stats');
        document.getElementById('admin-stats').innerHTML = `
            <div class="stat-card blue"><div class="stat-icon">📋</div><div class="stat-value">${stats.tables?.length || 0}</div><div class="stat-label">Tables</div></div>
            <div class="stat-card green"><div class="stat-icon">👁️</div><div class="stat-value">${stats.views?.length || 0}</div><div class="stat-label">Views</div></div>
            <div class="stat-card yellow"><div class="stat-icon">⚡</div><div class="stat-value">${stats.triggers?.length || 0}</div><div class="stat-label">Triggers</div></div>
            <div class="stat-card purple"><div class="stat-icon">⚙️</div><div class="stat-value">${stats.routines?.length || 0}</div><div class="stat-label">Routines</div></div>
        `;
    } catch (e) {}
}

async function loadAuditLog() {
    try {
        const logs = await api('/api/audit-log');
        document.getElementById('admin-audit-content').innerHTML = `<div class="card"><div class="card-header"><h3>📜 Audit Log (Latest 100)</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr>
                <th>ID</th><th>Table</th><th>Operation</th><th>Record ID</th><th>Old Values</th><th>New Values</th><th>By</th><th>Time</th>
            </tr></thead><tbody>${logs.map(l => `<tr>
                <td>${l.log_id}</td>
                <td class="text-blue">${l.table_name}</td>
                <td>${statusBadge(l.operation === 'INSERT' ? 'CONFIRMED' : l.operation === 'DELETE' ? 'CANCELLED' : 'DELAYED').replace(/CONFIRMED|CANCELLED|DELAYED/g, l.operation)}</td>
                <td>${l.record_id || '—'}</td>
                <td class="text-muted" style="max-width:200px;white-space:normal;font-size:11px">${l.old_values ? JSON.stringify(l.old_values) : '—'}</td>
                <td class="text-muted" style="max-width:200px;white-space:normal;font-size:11px">${l.new_values ? JSON.stringify(l.new_values) : '—'}</td>
                <td>${l.performed_by}</td>
                <td class="text-muted">${formatDate(l.performed_at)}</td>
            </tr>`).join('')}</tbody></table></div></div>`;
    } catch (e) {}
}

async function loadDBInfo() {
    try {
        const stats = await api('/api/admin/stats');
        let html = `<div class="card mb-2"><div class="card-header"><h3>📋 Tables (${stats.tables?.length || 0})</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr><th>Table</th><th>Rows</th><th>Data Size</th><th>Index Size</th></tr></thead>
            <tbody>${(stats.tables || []).map(t => `<tr>
                <td class="text-blue"><strong>${t.TABLE_NAME}</strong></td>
                <td>${t.TABLE_ROWS || 0}</td>
                <td class="text-muted">${((t.DATA_LENGTH || 0) / 1024).toFixed(1)} KB</td>
                <td class="text-muted">${((t.INDEX_LENGTH || 0) / 1024).toFixed(1)} KB</td>
            </tr>`).join('')}</tbody></table></div></div>`;

        html += `<div class="card mb-2"><div class="card-header"><h3>⚡ Triggers (${stats.triggers?.length || 0})</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr><th>Trigger</th><th>Event</th><th>Table</th><th>Timing</th></tr></thead>
            <tbody>${(stats.triggers || []).map(t => `<tr>
                <td class="text-yellow"><strong>${t.TRIGGER_NAME}</strong></td>
                <td>${t.EVENT_MANIPULATION}</td>
                <td>${t.EVENT_OBJECT_TABLE}</td>
                <td>${t.ACTION_TIMING}</td>
            </tr>`).join('')}</tbody></table></div></div>`;

        html += `<div class="card mb-2"><div class="card-header"><h3>⚙️ Functions & Procedures (${stats.routines?.length || 0})</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr><th>Name</th><th>Type</th></tr></thead>
            <tbody>${(stats.routines || []).map(r => `<tr>
                <td class="text-purple"><strong>${r.ROUTINE_NAME}</strong></td>
                <td>${r.ROUTINE_TYPE}</td>
            </tr>`).join('')}</tbody></table></div></div>`;

        html += `<div class="card"><div class="card-header"><h3>👁️ Views (${stats.views?.length || 0})</h3></div>
            <div class="card-body"><table class="data-table"><thead><tr><th>View Name</th></tr></thead>
            <tbody>${(stats.views || []).map(v => `<tr><td class="text-green"><strong>${v.TABLE_NAME}</strong></td></tr>`).join('')}</tbody></table></div></div>`;

        document.getElementById('admin-dbinfo-content').innerHTML = html;
    } catch (e) {}
}

// ============================================================
// SQL CONSOLE
// ============================================================

const sqlTemplates = {
    dashboard: `SELECT * FROM vw_flight_dashboard ORDER BY scheduled_departure;`,
    stats: `SELECT * FROM vw_airline_statistics;`,
    revenue: `SELECT * FROM vw_revenue_report ORDER BY flight_date DESC;`,
    delayed: `SELECT * FROM vw_delayed_flights;`,
    leftjoin: `-- LEFT OUTER JOIN: All flights including those without gate assignments
SELECT f.flight_id, f.flight_number, a.airline_name, f.origin_airport, f.destination_airport,
       f.status, g.gate_number, t.terminal_name,
       CASE WHEN g.gate_number IS NULL THEN '** NO GATE **' ELSE CONCAT(t.terminal_name, '-', g.gate_number) END AS gate_info
FROM flights f
LEFT OUTER JOIN gate_assignments ga ON f.flight_id = ga.flight_id AND ga.status = 'ACTIVE'
LEFT OUTER JOIN gates g ON ga.gate_id = g.gate_id
LEFT OUTER JOIN terminals t ON g.terminal_id = t.terminal_id
JOIN airlines a ON f.airline_id = a.airline_id
ORDER BY f.scheduled_departure;`,
    rightjoin: `-- RIGHT OUTER JOIN: All gates including those with no flights
SELECT g.gate_number, t.terminal_name, g.gate_type, g.is_available,
       f.flight_number, f.destination_airport,
       CASE WHEN f.flight_number IS NULL THEN '** GATE EMPTY **' ELSE CONCAT(f.flight_number, ' → ', f.destination_airport) END AS assignment_info
FROM gate_assignments ga
RIGHT OUTER JOIN gates g ON ga.gate_id = g.gate_id AND ga.status = 'ACTIVE'
JOIN terminals t ON g.terminal_id = t.terminal_id
LEFT JOIN flights f ON ga.flight_id = f.flight_id
ORDER BY t.terminal_name, g.gate_number;`,
    fulljoin: `-- FULL OUTER JOIN (Emulated via UNION): All employees and flight assignments
SELECT e.employee_id, CONCAT(e.first_name, ' ', e.last_name) AS name, e.employee_type,
       fca.role, f.flight_number, f.scheduled_departure,
       CASE WHEN f.flight_number IS NULL THEN '** NO FLIGHT **' ELSE 'Assigned' END AS status
FROM employees e
LEFT OUTER JOIN flight_crew_assignments fca ON e.employee_id = fca.employee_id
LEFT OUTER JOIN flights f ON fca.flight_id = f.flight_id
WHERE e.employee_type IN ('PILOT','CABIN_CREW')
UNION
SELECT e.employee_id, CONCAT(e.first_name, ' ', e.last_name), e.employee_type,
       fca.role, f.flight_number, f.scheduled_departure,
       CASE WHEN e.employee_id IS NULL THEN '** NO CREW **' ELSE 'Assigned' END
FROM flight_crew_assignments fca
RIGHT OUTER JOIN employees e ON fca.employee_id = e.employee_id
RIGHT OUTER JOIN flights f ON fca.flight_id = f.flight_id
WHERE e.employee_id IS NULL
ORDER BY name, flight_number;`,
    functions: `-- Using custom functions
SELECT f.flight_number, f.origin_airport, f.destination_airport,
       fn_calculate_flight_duration(f.flight_id) AS duration_min,
       fn_flight_occupancy(f.flight_id) AS occupancy_pct,
       CASE WHEN fn_flight_occupancy(f.flight_id) >= 80 THEN 'HIGH'
            WHEN fn_flight_occupancy(f.flight_id) >= 50 THEN 'MODERATE'
            ELSE 'LOW' END AS demand
FROM flights f WHERE f.status != 'CANCELLED' ORDER BY occupancy_pct DESC;`,
    window: `-- Window Functions: Ranking passengers by spending
SELECT CONCAT(p.first_name, ' ', p.last_name) AS passenger, b.booking_class, b.price,
       f.flight_number, al.airline_name,
       RANK() OVER (ORDER BY b.price DESC) AS spending_rank,
       DENSE_RANK() OVER (PARTITION BY al.airline_id ORDER BY b.price DESC) AS airline_rank,
       SUM(b.price) OVER (PARTITION BY al.airline_id) AS airline_total
FROM bookings b
JOIN passengers p ON b.passenger_id = p.passenger_id
JOIN flights f ON b.flight_id = f.flight_id
JOIN airlines al ON f.airline_id = al.airline_id
WHERE b.booking_status != 'CANCELLED' ORDER BY spending_rank;`,
    cte: `-- CTE: Flight delay analysis with reliability rating
WITH delay_stats AS (
    SELECT a.airline_name, COUNT(*) AS total_flights,
           SUM(CASE WHEN f.delay_minutes > 0 THEN 1 ELSE 0 END) AS delayed,
           AVG(CASE WHEN f.delay_minutes > 0 THEN f.delay_minutes END) AS avg_delay
    FROM flights f JOIN airlines a ON f.airline_id = a.airline_id GROUP BY a.airline_id, a.airline_name
)
SELECT *, ROUND((1 - delayed/total_flights) * 100, 1) AS on_time_pct,
       CASE WHEN (delayed/total_flights) < 0.1 THEN 'EXCELLENT'
            WHEN (delayed/total_flights) < 0.25 THEN 'GOOD'
            WHEN (delayed/total_flights) < 0.5 THEN 'FAIR' ELSE 'POOR' END AS rating
FROM delay_stats ORDER BY on_time_pct DESC;`
};

function sqlTemplate(name) {
    document.getElementById('sql-input').value = sqlTemplates[name] || '';
}

async function executeSQL() {
    const sql = document.getElementById('sql-input').value.trim();
    if (!sql) return;

    const resultDiv = document.getElementById('sql-result');
    resultDiv.innerHTML = '<div class="loading"><div class="spinner"></div>Executing...</div>';

    try {
        const data = await api('/api/admin/query', { method: 'POST', body: { sql } });

        if (Array.isArray(data) && data.length > 0 && Array.isArray(data[0])) {
            // Multiple result sets
            resultDiv.innerHTML = data.map((resultSet, i) => renderResultTable(resultSet, i)).join('');
        } else if (Array.isArray(data) && data.length > 0) {
            resultDiv.innerHTML = renderResultTable(data, 0);
        } else {
            resultDiv.innerHTML = '<div class="result-panel"><div class="result-header">✅ Query executed — no rows returned</div></div>';
        }
        toast(`Query returned ${Array.isArray(data) ? (Array.isArray(data[0]) ? data.reduce((s,r)=>s+r.length,0) : data.length) : 0} rows`, 'success');
    } catch (e) {
        resultDiv.innerHTML = `<div class="result-panel"><div class="result-header" style="background:rgba(239,68,68,0.06);color:var(--accent-red)">❌ Error</div><div class="result-body padded"><pre style="color:var(--accent-red);white-space:pre-wrap">${e.message}</pre></div></div>`;
    }
}

function renderResultTable(rows, setIndex) {
    if (!rows || rows.length === 0) return '';
    const cols = Object.keys(rows[0]);
    return `
        <div class="result-panel mt-1">
            <div class="result-header">✅ Result Set ${setIndex + 1} — ${rows.length} row${rows.length !== 1 ? 's' : ''}</div>
            <div class="result-body">
                <table class="data-table">
                    <thead><tr>${cols.map(c => `<th>${c}</th>`).join('')}</tr></thead>
                    <tbody>${rows.map(r => `<tr>${cols.map(c => {
                        let v = r[c];
                        if (v === null || v === undefined) v = '<span class="text-muted">NULL</span>';
                        else if (typeof v === 'object') v = `<span class="text-muted">${JSON.stringify(v)}</span>`;
                        return `<td>${v}</td>`;
                    }).join('')}</tr>`).join('')}</tbody>
                </table>
            </div>
        </div>`;
}

// Ctrl+Enter to execute SQL
document.addEventListener('keydown', e => {
    if (e.ctrlKey && e.key === 'Enter' && document.getElementById('module-admin').classList.contains('active')) {
        executeSQL();
    }
});

// ============================================================
// INITIAL LOAD
// ============================================================

loadFlights();
