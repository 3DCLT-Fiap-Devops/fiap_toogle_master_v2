variable "region" {
  description = "AWS region"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "lab_role_name" {
  description = "The name of the IAM role to use (for AWS Academy/Lab environments)"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}
