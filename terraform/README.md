# Infrastructure as Code with Terraform - ToogleMaster

This directory contains the Terraform configuration to provision the AWS infrastructure for the ToogleMaster project.

## Resources Provisioned

- **Networking**: VPC, Subnets (2 AZs), IGW, Route Tables, and Security Groups.
- **RDS PostgreSQL**:
    - `auth-db`: Instance for authentication data.
    - `main-db`: Instance for flags and targeting data.
- **ECR Repositories**: 5 repositories for the microservices.
- **SQS**: `toogle-events` queue.
- **DynamoDB**: `analytics_events` table.
- **Redis (ElastiCache)**: `toogle-redis` cluster.
- **EKS**: Kubernetes cluster (`toogle-cluster`) and a managed Node Group.

## Prerequisites

1.  **Terraform CLI** installed.
2.  **AWS CLI** configured with appropriate credentials.
3.  **Permissions**: Ensure you have permissions to manage the listed resources. This setup is optimized for **AWS Academy / Lab environments** by reusing the existing `LabRole`.

## Usage

1.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

2.  **Review the Plan**:
    ```bash
    terraform plan
    ```

3.  **Apply the Changes**:
    ```bash
    terraform apply
    ```

4.  **Retrieve Outputs**:
    After a successful apply, Terraform will display the endpoints for RDS, Redis, SQS, and EKS. You can also view them anytime using:
    ```bash
    terraform output
    ```

## Variables

You can customize the setup by creating a `terraform.tfvars` file or passing variables via CLI:

- `region`: AWS region (default: `us-east-1`).
- `db_password`: Master password for RDS (default: `SenhaTeste123`).
- `lab_role_name`: The name of the existing IAM role for EKS (default: `LabRole`).

## Why Terraform?

This replaces the previous Bash scripts (`aws-infra/`) with a declarative approach, ensuring:
- **State Management**: Terraform keeps track of what was created.
- **Idempotency**: Running `apply` multiple times won't create duplicate resources.
- **Ease of Cleanup**: Remove everything with a single command:
    ```bash
    terraform destroy
    ```
