#!/bin/bash

# RDS Postgres Instances
# 2x 20GB t3.medium
PASSWORD="SenhaTeste123"

echo "Creating RDS Postgres Instance: auth-db..."
aws rds create-db-instance \
    --db-instance-identifier auth-db \
    --db-instance-class db.t3.medium \
    --engine postgres \
    --allocated-storage 20 \
    --master-username "dbuser" \
    --master-user-password "$PASSWORD" \
    --backup-retention-period 7 \
    --publicly-accessible \
    --tags Key=Project,Value=ToogleMaster Key=Service,Value=Auth > outputs/rds-auth.json

echo "Creating RDS Postgres Instance: main-db..."
aws rds create-db-instance \
    --db-instance-identifier main-db \
    --db-instance-class db.t3.medium \
    --engine postgres \
    --allocated-storage 20 \
    --master-username "dbuser" \
    --master-user-password "$PASSWORD" \
    --backup-retention-period 7 \
    --publicly-accessible \
    --tags Key=Project,Value=ToogleMaster Key=Service,Value=Core > outputs/rds-main.json
