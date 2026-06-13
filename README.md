# ✈️ SkyPort International Airport — Database Management System

A comprehensive airport database system built for a university Database course project. Models all operations of a large international airport including flight scheduling, passenger management, baggage handling, cargo, maintenance, commercial operations, and more.

## 📊 Technical Overview

| Component | Count |
|-----------|-------|
| Tables | 28 (including 4 inheritance tables) |
| Triggers | 12 |
| Functions | 6 |
| Stored Procedures | 6 |
| Views | 11 |
| Atomic Transactions | 4 |
| Concurrency Control | 3 examples |
| Roles & Users | 6 roles, 6 users |

## 🛠️ Technology Stack

- **Database**: MySQL 8.0+
- **Backend**: Node.js + Express
- **Frontend**: Vanilla HTML/CSS/JS (Dark theme admin dashboard)
- **Driver**: mysql2

## 🚀 Quick Start

### Prerequisites
- MySQL 8.0+ installed and running
- Node.js 16+ installed

### 1. Setup Database
```bash
# Connect to MySQL and run scripts in order:
mysql -u root -p < database/01_create_database.sql
mysql -u root -p skyport_airport < database/02_triggers.sql
mysql -u root -p skyport_airport < database/03_functions_procedures.sql
mysql -u root -p skyport_airport < database/04_views.sql
mysql -u root -p skyport_airport < database/05_seed_data.sql

# Optional (for documentation purposes):
mysql -u root -p skyport_airport < database/06_transactions.sql
mysql -u root -p skyport_airport < database/07_concurrency.sql
mysql -u root -p skyport_airport < database/08_privileges_roles.sql
mysql -u root -p skyport_airport < database/09_normalization_examples.sql
```

### 2. Start Server
```bash
cd server
npm install
npm start
```

### 3. Open Dashboard
Navigate to `http://localhost:3000`

### 4. Configure Database Connection (if needed)
Set environment variables:
```bash
set DB_HOST=localhost
set DB_PORT=3306
set DB_USER=root
set DB_PASS=yourpassword
```

## 📁 Project Structure

```
DB-PROJE/
├── database/
│   ├── 01_create_database.sql      — 28 tables with constraints
│   ├── 02_triggers.sql             — 12 triggers
│   ├── 03_functions_procedures.sql — 6 functions + 6 procedures
│   ├── 04_views.sql                — 11 views
│   ├── 05_seed_data.sql            — Realistic mock data
│   ├── 06_transactions.sql         — 4 atomic transaction demos
│   ├── 07_concurrency.sql          — 3 concurrency control examples
│   ├── 08_privileges_roles.sql     — 6 roles + 6 users
│   ├── 09_normalization_examples.sql — 3NF & BCNF demonstrations
│   └── 10_sample_queries.sql       — Advanced queries & outer joins
├── server/
│   ├── server.js                   — Express REST API
│   └── package.json
├── public/
│   ├── index.html                  — Dashboard SPA
│   ├── style.css                   — Dark theme CSS
│   └── app.js                      — Frontend logic
└── docs/
    └── test_scenarios.md           — Complete test guide
```

## 🎯 Features Demonstrated

### Database Features
- **Inheritance**: Employee → Pilot / Cabin Crew / Ground Staff / Security
- **Normalization**: 3NF & BCNF with decomposition examples
- **Triggers**: Auto boarding pass, status logging, weight validation, audit trail
- **Views**: Flight dashboard, airline stats, baggage tracking, revenue reports
- **Stored Procedures**: Booking, cancellation, check-in, transfer (all transactional)
- **Functions**: Flight duration, occupancy rate, airline revenue, passenger miles
- **Transactions**: Atomic booking, cancellation, gate reassignment, passenger transfer
- **Concurrency**: Pessimistic locking (FOR UPDATE), optimistic locking, row-level locking
- **Outer Joins**: LEFT, RIGHT, and FULL (emulated) outer joins
- **Advanced SQL**: Subqueries, CTEs, window functions, EXISTS, self-joins

### UI Features
- 7 module dashboard with sidebar navigation
- Quick-action shortcut buttons for easy testing
- SQL Console with pre-built query templates
- Real-time status badges and data tables
- CRUD operations for all major entities
- Audit log viewer
- Database introspection (tables, triggers, views, routines)

## 📝 Test Guide
See [docs/test_scenarios.md](docs/test_scenarios.md) for complete testing instructions.
