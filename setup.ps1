# setup.ps1 - Clean setup for Flask + PostgreSQL + init_db.py with fresh venv on Windows

# --- Step 1: Variables ---
$DB_name = "flask_db"
$DB_user = "elhad"       # Change to your preferred DB username
$DB_pass = "elhad123"

# --- Step 2: Remove old virtual environment ---
if (Test-Path "venv") {
    Write-Host "Removing old virtual environment..."
    Remove-Item -Recurse -Force venv
}

# --- Step 3: Install Python packages ---
Write-Host "Upgrading pip..."
python -m pip install --upgrade pip

Write-Host "Installing Python dependencies..."
python -m pip install Flask Flask-Session Flask-Mail Flask-SQLAlchemy Flask-WTF `
email-validator psycopg2-binary Flask-Caching python-dotenv pyautogui

# --- Step 4: Start PostgreSQL service (Windows) ---
Write-Host "Starting PostgreSQL service..."
Start-Service -Name postgresql-x64-14  -ErrorAction SilentlyContinue

# --- Step 5: Drop old database/user if they exist ---
Write-Host "Dropping old database and user if they exist..."
psql -U postgres -c "DROP DATABASE IF EXISTS $DB_name;"
psql -U postgres -c "DROP USER IF EXISTS $DB_user;"

# --- Step 6: Create new database and user ---
Write-Host "Creating PostgreSQL database and user..."
psql -U postgres -c "CREATE DATABASE $DB_name;"
psql -U postgres -c "CREATE USER $DB_user WITH PASSWORD '$DB_pass';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_name TO $DB_user;"

# --- Step 7: Grant privileges on all tables and sequences ---
psql -U postgres -d $DB_name -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_user;"
psql -U postgres -d $DB_name -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_user;"
psql -U postgres -d $DB_name -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $DB_user;"

# --- Step 8: Save environment variables to .env ---
Write-Host "Saving environment variables..."
$envContent = @"
FLASK_APP=app
FLASK_ENV=development
DB_USERNAME=$DB_user
DB_PASSWORD=$DB_pass
DB_NAME=$DB_name
DB_HOST=localhost
"@
$envContent | Out-File -Encoding ASCII ".env"

# --- Step 9: Create fresh virtual environment ---
Write-Host "Creating virtual environment..."
python -m venv venv

# --- Step 10: Run init_db.py ---
Write-Host "Initializing database tables..."
python init_db.py

Write-Host "Setup complete!"
Write-Host "Activate the virtual environment with: .\venv\Scripts\Activate.ps1"
Write-Host "Run the Flask app with: flask run"
