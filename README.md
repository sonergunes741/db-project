# SkyPort Airport Database Management System

A comprehensive, highly normalized relational database project designed for a university database management course. This project models the complex operations of an international airport and features a technical test panel for validating database logic.

## 🌟 Key Features

- **Complex Schema:** 28 tables in 3NF/BCNF modeling flights, passengers, baggage, crew, gates, and maintenance.
- **Class Table Inheritance:** Base `employees` table extending to `pilots`, `cabin_crew`, `ground_staff`, etc.
- **Data Integrity:** 12 triggers enforcing business rules (e.g., gate conflicts, baggage weight limits).
- **Transactions:** 6 stored procedures with atomic transactions and rollback mechanisms.
- **Calculated Logic:** 6 functions for dynamic calculations (flight duration, occupancy, revenue).
- **Technical Test Panel:** A custom-built Node.js/Express frontend that acts as a technical console to execute and visualize SQL queries, test triggers, and run transactions.

---

## 🚀 How to Run the Project from Scratch

Follow these steps to set up the database and run the technical test panel on your local machine.

### Step 1: Start MySQL and Apache
1. Open your **XAMPP Control Panel**.
2. Click **Start** next to both **Apache** and **MySQL**. (Both should turn green).

### Step 2: Import the Database
1. Open your web browser and go to: `http://localhost/phpmyadmin`
2. Click **New** on the left sidebar to create a new database.
3. Name the database **`skyport_airport`** and click Create.
4. Select the `skyport_airport` database you just created.
5. Click the **Import** tab at the top.
6. Import the SQL files located in the `database/` folder **in numerical order**:
   - `01_create_database.sql` (Creates the 28 tables)
   - `02_triggers.sql` (Adds the 12 triggers)
   - `03_functions_procedures.sql` (Adds functions and stored procedures)
   - `04_views.sql` (Adds the views)
   - `05_seed_data.sql` (Fills the tables with realistic mockup data)
   
   *(Note: Files 06 to 10 contain advanced queries and transaction examples for your reference, you don't need to import them to run the app).*

### Step 3: Start the Node.js Server
1. Open a terminal (Command Prompt or PowerShell).
2. Navigate to the `server` folder inside the project directory:
   ```bash
   cd path/to/DB-PROJE/server
   ```
3. Install the required packages (you only need to do this once):
   ```bash
   npm install
   ```
4. Start the server:
   ```bash
   npm start
   ```
   *You should see a message saying "Server running on http://localhost:3000" and "✅ Connected to MySQL - skyport_airport database".*

### Step 4: Access the Technical Test Panel
1. Open your web browser and go to: **`http://localhost:3000`**
2. You will see the **DB Test Panel**. 
3. Click the buttons on the left sidebar to test Triggers, Functions, Procedures, Views, and Transactions. The panel will show you exactly which SQL queries are being executed in the background and display the raw data returned from the database.
