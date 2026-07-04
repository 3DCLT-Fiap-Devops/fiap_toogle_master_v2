#!/bin/bash

# Script to seed RDS databases using a temporary Docker container
# Reads database hosts directly from Kustomize .env configuration files.

DOCKER_SQL_DIR="../docker"
K8S_DIR="../k8s"

if [ ! -d "$K8S_DIR" ]; then
    K8S_DIR="k8s"
    DOCKER_SQL_DIR="docker"
fi

if [ ! -f "$K8S_DIR/auth.env" ] || [ ! -f "$K8S_DIR/flag.env" ] || [ ! -f "$K8S_DIR/targeting.env" ]; then
    echo "Error: K8s .env files not found in $K8S_DIR/. Run generate-summary.sh or deploy-helper.sh first."
    exit 1
fi

echo "Reading database configuration from K8s .env files..."

# Function to parse DB host from DATABASE_URL env line
parse_host() {
    local env_file=$1
    grep "DATABASE_URL=" "$env_file" | sed -n 's|.*@\(.*\):5432.*|\1|p'
}

AUTH_DB_HOST=$(parse_host "$K8S_DIR/auth.env")
MAIN_DB_HOST=$(parse_host "$K8S_DIR/flag.env")
TARGETING_DB_HOST=$(parse_host "$K8S_DIR/targeting.env")

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
create_db_if_missing $TARGETING_DB_HOST "targeting_db"

echo "--------------------------------------------------------"
echo "Step 2: Seeding Auth Database (auth_db)..."
SQL_ABS_PATH=$(cd "$DOCKER_SQL_DIR" && pwd)

MSYS_NO_PATHCONV=1 docker run --rm -v "$SQL_ABS_PATH:/sql" \
    -e PGPASSWORD=$DB_PASS \
    postgres:alpine \
    psql -h $AUTH_DB_HOST -U $DB_USER -d auth_db -f /sql/init-auth.sql

echo "--------------------------------------------------------"
echo "Seeding Flag Database (flag_db)..."
MSYS_NO_PATHCONV=1 docker run --rm -v "$SQL_ABS_PATH:/sql" \
    -e PGPASSWORD=$DB_PASS \
    postgres:alpine \
    psql -h $MAIN_DB_HOST -U $DB_USER -d flag_db -f /sql/init-main.sql

echo "--------------------------------------------------------"
echo "Seeding Targeting Database (targeting_db)..."
MSYS_NO_PATHCONV=1 docker run --rm -v "$SQL_ABS_PATH:/sql" \
    -e PGPASSWORD=$DB_PASS \
    postgres:alpine \
    psql -h $TARGETING_DB_HOST -U $DB_USER -d targeting_db -f /sql/init-main.sql

echo "--------------------------------------------------------"
echo "Database seeding complete!"
echo "--------------------------------------------------------"
