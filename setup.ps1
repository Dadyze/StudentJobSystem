# setup.ps1 - Clean setup for Flask + PostgreSQL + init_db.py on Windows

# --- Step 1: Variables ---
$DB_name = "flask_db"
$DB_user = "elhad"
$DB_pass = "elhad123"

# --- Step 2: Check for Python ---
Write-Host "Checking for Python..."
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Found Python: $pythonVersion"
} catch {
    Write-Error "Python is not installed. Please install Python 3.10+ from https://www.python.org/downloads/ OR Windows Store"
    exit 1
}
# --- Step 3: Check for psql (PostgreSQL client) ---
Write-Host "Checking for psql (PostgreSQL client)..."
try {
    $psqlVersion = psql --version 2>&1
    Write-Host "Found psql: $psqlVersion"
} catch {
    Write-Warning "psql not found! Attempting to add PostgreSQL to PATH..."
    
    # Add PostgreSQL bin folder to PATH
    $pgPath = "C:\Program Files\PostgreSQL\15\bin"
    if (Test-Path $pgPath) {
        $env:Path += ";$pgPath"
        Write-Host "Added PostgreSQL to PATH. Retrying..."
        try {
            $psqlVersion = psql --version 2>&1
            Write-Host "Found psql: $psqlVersion"
        } catch {
            Write-Warning "Still cannot find psql. Please install PostgreSQL via winget:"
            Write-Host "  winget install --id PostgreSQL.PostgreSQL.15"
            exit 1
        }
    } else {
        Write-Warning "PostgreSQL bin folder not found at $pgPath."
        Write-Host "Please install PostgreSQL"
        exit 1
    }
}



# --- Step 4: Remove old virtual environment ---
if (Test-Path "venv") {
    Write-Host "Removing old virtual environment..."
    Remove-Item -Recurse -Force venv
}

Write-Host "Installing Python dependencies..."
python -m pip install Flask Flask-Session Flask-Mail Flask-SQLAlchemy Flask-WTF `
email-validator psycopg2-binary Flask-Caching python-dotenv pyautogui

# --- Step 6: Start PostgreSQL service ---
Write-Host "Starting PostgreSQL service..."
try {
    Start-Service -Name postgresql-x64-15 -ErrorAction SilentlyContinue
} catch {
    Write-Warning "Could not start PostgreSQL service. Make sure it is installed and running."
}

# --- Step 7: Drop old database/user ---
Write-Host "Dropping old database and user if they exist..."
& psql -U postgres -c "DROP DATABASE IF EXISTS $DB_name;"
& psql -U postgres -c "DROP USER IF EXISTS $DB_user;"

# --- Step 8: Create new database and user ---
Write-Host "Creating PostgreSQL database and user..."
& psql -U postgres -c "CREATE DATABASE $DB_name;"
& psql -U postgres -c "CREATE USER $DB_user WITH PASSWORD '$DB_pass';"
& psql -U postgres -d $DB_name -c "GRANT ALL PRIVILEGES ON SCHEMA public TO $DB_user;"
& psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_name TO $DB_user;"
& psql -U postgres -d $DB_name -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_user;"
& psql -U postgres -d $DB_name -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_user;"
& psql -U postgres -d $DB_name -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $DB_user;"

# --- Step 10: Export environment variables (Windows PowerShell) ---
Write-Host "Exporting environment variables..."
$env:FLASK_APP = "app"
$env:FLASK_ENV = "development"
$env:DB_USERNAME = $DB_user
$env:DB_PASSWORD = $DB_pass
$env:DB_NAME = $DB_name


# --- Step 9: Save environment variables to .env ---
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


# --- Step 10: Create fresh virtual environment ---
Write-Host "Creating virtual environment..."
python3 -m venv venv

# --- Step 11: Run init_db.py ---
Write-Host "Initializing database tables..."
python3 -m pip install python-dotenv
python3 init_db.py

Write-Host "Setup complete!"
Write-Host "Activate the virtual environment with: .\venv\Scripts\Activate.ps1"
Write-Host "Run the Flask app with: python3 -m flask run"
# setup.ps1 - Clean setup for Flask + PostgreSQL + init_db.py on Windows
