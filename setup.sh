#!/bin/bash
# setup.sh - Clean setup for Flask + PostgreSQL + init_db.py with fresh venv

# --- Step 1: Variables ---

DB_name="flask_db"
DB_user="elhad"      # Change this to your preferred DB username
DB_pass="elhad123"

# --- Step 2: Remove old virtual environment ---
if [ -d "venv" ]; then
    echo "Removing old virtual environment..."
    rm -rf venv
fi

# --- Step 3: Update system and install packages ---
echo "Updating system..."
sudo apt-get update

echo "Installing required packages..."
sudo apt-get install -y python3-venv python3-pip postgresql postgresql-contrib libpq-dev


echo "Upgrading pip..."
pip install --upgrade pip

echo "Installing Python dependencies..."
pip install Flask Flask-Session Flask-Mail Flask-SQLAlchemy Flask-WTF email-validator psycopg2-binary Flask-Caching python-dotenv pyautogui


# Save current directory
CURRENT_DIR=$(pwd)

# Use a directory postgres can access
cd /tmp || exit


# --- Step 4: Start PostgreSQL service ---
echo "Starting PostgreSQL..."
sudo service postgresql start

# --- Step 5: Drop old DB/user if they exist ---
echo "Dropping old database and user if they exist..."
sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS $DB_name;
DROP USER IF EXISTS $DB_user;
EOF

# --- Step 6: Create new DB and user ---
echo "Creating PostgreSQL database and user..."
sudo -u postgres psql <<EOF
CREATE DATABASE $DB_name;
CREATE USER $DB_user WITH PASSWORD '$DB_pass';
GRANT ALL PRIVILEGES ON DATABASE $DB_name TO $DB_user;
EOF

# --- Step 7: Grant privileges on all tables and sequences ---
sudo -u postgres psql -d $DB_name <<EOF
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO $DB_user;
EOF

# --- Step 8: Export environment variables ---
export FLASK_APP=app
export FLASK_ENV=development
export DB_USERNAME=$DB_user
export DB_PASSWORD=$DB_pass
export DB_NAME=$DB_name

# Save to .env for Flask
cat > .env <<EOL
FLASK_APP=app
FLASK_ENV=development
DB_USERNAME=$DB_user
DB_PASSWORD=$DB_pass
DB_NAME=$DB_name
DB_HOST=localhost
EOL
cd "$CURRENT_DIR" || exit
#  Create fresh virtual environment ---
echo "Creating virtual environment..."
python3 -m venv venv



# --- Step 9: Run init_db.py ---
echo "Initializing database tables..."
python3 init_db.py

echo "Setup complete!"
echo "Activate the virtual environment with: source venv/bin/activate"
echo "Run the Flask app with: flask run"
