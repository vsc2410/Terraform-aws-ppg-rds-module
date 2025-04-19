# variables.tf
variable "region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "The environment (dev, staging, prod, etc.)"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_username" {
  description = "The username for the database"
  type        = string
}

variable "instance_class" {
  description = "The instance class for the RDS instance"
  type        = string
}

variable "allocated_storage" {
  description = "The allocated storage in GB"
  type        = number
}

variable "engine_version" {
  description = "The PostgreSQL engine version"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "secret_name" {
  description = "The name of the secret in AWS Secrets Manager"
  type        = string
  default     = "postgres-rds-password" # Default secret name
}

variable "password_length" {
  description = "The length of the generated password"
  type        = number
  default     = 25
}

variable "availability_zones" {
  description = "A list of Availability Zones for Multi-AZ deployments"
  type        = list(string)
  default     = []
}

variable "enable_rds_proxy" {
  description = "Whether to enable RDS Proxy"
  type        = bool
  default     = false
}

variable "proxy_name" {
  description = "The name of the RDS Proxy"
  type        = string
  default     = "postgres-proxy"
}

variable "db_subnet_ids" {
  description = "A list of subnet IDs for the RDS instance and Proxy."
  type        = list(string)
}

variable "postgres_port" {
  description = "The port for PostgreSQL traffic"
  type        = number
  default     = 5432
}

variable "security_group_name" {
  description = "Name for the security group"
  type        = string
  default     = "postgres-sg"
}

variable "security_group_description" {
  description = "Description for the security group"
  type        = string
  default     = "Allow postgres traffic"
}

variable "profile" {
  description = "The AWS profile to use"
  type        = string
  default     = "default" #  default profile.
}

variable "storage_type" {
  description = "The storage type for the RDS instance"
  type        = string
  default     = "gp2" # Add default value
}

variable "storage_throughput" {
  description = "The storage throughput for the RDS instance"
  type        = number
  default     = null # Add default value
}

variable "storage_encrypted" {
  description = "Whether the storage is encrypted"
  type        = bool
  default     = false # Add default value
}

variable "kms_key_id" {
  description = "The KMS key ID for encryption"
  type        = string
  default     = null
}

variable "replicate_source_db" {
  description = "The source DB instance identifier to replicate from"
  type        = string
  default     = null
}

variable "replica_mode" {
  description = "The replica mode"
  type        = string
  default     = null
}

variable "engine" {
  description = "The database engine to use (e.g., postgresql)"
  type        = string
}

variable "db_subnet_group_name" {
  description = "The name of the database subnet group"
  type        = string
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "Whether the RDS instance is publicly accessible"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Determines whether a final snapshot is created before the database instance is deleted."
  type        = bool
  default     = true # Set to true to skip snapshots by default
}
