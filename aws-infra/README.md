# AWS Infrastructure Setup - ToogleMaster

This directory contains shell scripts to provision the necessary AWS infrastructure for the ToogleMaster project using the AWS CLI.

## Prerequisites

1.  **AWS CLI** installed and configured (`aws configure`).
2.  **Permissions**: Ensure your IAM user/role has permissions to create RDS, ECR, SQS, DynamoDB, and ElastiCache resources.
3.  **VPC/Network**: These scripts use default settings. For production, you should specify `--vpc-security-group-ids` and `--db-subnet-group-name` for RDS/ElastiCache.

## Resources Provisioned

- **RDS Postgres**:
    - `auth-db`: 20GB, t3.medium
    - `main-db`: 20GB, t3.medium
- **ECR Repositories**:
    - `analytics-service`
    - `auth-service`
    - `evaluation-service`
    - `flag-service`
    - `targeting-service`
- **SQS**:
    - `toogle-events`
- **DynamoDB**:
    - `analytics_events` (Partition Key: `event_id`)
- **Redis (ElastiCache)**:
    - `toogle-redis`: cache.t3.medium, single node

## Usage

To provision everything at once:

```bash
chmod +x setup-all.sh
./setup-all.sh
```

Or run individual scripts:

```bash
./rds.sh
./ecr.sh
./sqs.sh
./dynamodb.sh
./redis.sh
```

## Build and Push Docker Images

Once the ECR repositories are created, you can build and push the images:

```bash
chmod +x build-and-push.sh
./build-and-push.sh
```

This script:
1. Detects your AWS Account ID and Region.
2. Performs `docker login` to ECR.
3. Builds all 5 microservices using the Dockerfiles in `docker/`.
4. Tags and pushes them to your ECR registries.

## Cleanup (Delete All)

To delete all provisioned resources and clean up the `outputs` directory:

```bash
chmod +x delete-all.sh
./delete-all.sh
```

**WARNING:** This action is irreversible and will delete all data in RDS and DynamoDB.

## Security Note

The RDS scripts use a placeholder password `change-me-securely`. **Change this password** before running the scripts or use AWS Secrets Manager to handle credentials.
