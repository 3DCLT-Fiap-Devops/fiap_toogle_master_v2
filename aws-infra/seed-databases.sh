#!/bin/bash

# Script to seed RDS databases using a temporary Docker container
# This avoids the need for a local psql installation.

SUMMARY_FILE="deployment-summary.txt"
DOCKER_SQL_DIR="../docker"

if [ ! -f "$SUMMARY_FILE" ]; then
    echo "Error: $SUMMARY_FILE not found. Run generate-summary.sh first."
    exit 1
fi

echo "Reading database configuration from $SUMMARY_FILE..."

# Extracting endpoints and credentials
AUTH_DB_HOST=$(grep "RDS Auth-DB Endpoint:" "$SUMMARY_FILE" | awk '{print $4}')
MAIN_DB_HOST=$(grep "RDS Main-DB Endpoint:" "$SUMMARY_FILE" | awk '{print $4}')
DB_USER="dbuser"
DB_PASS="SenhaTeste123"

# Check if docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker to run this script."
    exit 1
fi

echo "--------------------------------------------------------"
echo "Step 1: Creating databases if they don't exist..."

# Function to create DB if it doesn't exist
create_db_if_missing() {
    local host=$1
    local dbname=$2
    echo "Checking/Creating database $dbname on $host..."
    docker run --rm -e PGPASSWORD=$DB_PASS postgres:alpine \
        psql -h $host -U $DB_USER -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '$dbname'" | grep -q 1 || \
        docker run --rm -e PGPASSWORD=$DB_PASS postgres:alpine \
        psql -h $host -U $DB_USER -d postgres -c "CREATE DATABASE $dbname"
}

create_db_if_missing $AUTH_DB_HOST "auth_db"
create_db_if_missing $MAIN_DB_HOST "flag_db"
create_db_if_missing $MAIN_DB_HOST "targeting_db"

echo "--------------------------------------------------------"
echo "Step 2: Seeding Auth Database (auth_db)..."
# Use absolute paths and disable MSYS path conversion for Windows
SQL_ABS_PATH=$(cd "$DOCKER_SQL_DIR" && pwd)

MSYS_NO_PATHCONV=1 docker run --rm -v "$SQL_ABS_PATH:/sql" \
    -e PGPASSWORD=$DB_PASS \
    postgres:alpine \
    psql -h $AUTH_DB_HOST -U $DB_USER -d auth_db -f /sql/init-auth.sql

echo "--------------------------------------------------------"
echo "Seeding Main Database (flag_db and targeting_db)..."
MSYS_NO_PATHCONV=1 docker run --rm -v "$SQL_ABS_PATH:/sql" \
    -e PGPASSWORD=$DB_PASS \
    postgres:alpine \
    psql -h $MAIN_DB_HOST -U $DB_USER -d flag_db -f /sql/init-main.sql

MSYS_NO_PATHCONV=1 docker run --rm -v "$SQL_ABS_PATH:/sql" \
    -e PGPASSWORD=$DB_PASS \
    postgres:alpine \
    psql -h $MAIN_DB_HOST -U $DB_USER -d targeting_db -f /sql/init-main.sql

echo "--------------------------------------------------------"
echo "Database seeding complete!"
echo "--------------------------------------------------------"
