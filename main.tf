# main.tf
# Create Security Group
resource "aws_security_group" "postgres_sg" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.postgres_port
    to_port     = var.postgres_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-postgres-sg"
    Environment = var.environment
  }
}

# Create a new secret in AWS Secrets Manager for the PostgreSQL password
resource "aws_secretsmanager_secret" "postgres_password_secret" {
  name = var.secret_name
  #  recovery_window_in_days = 7 # Removed from here
}

resource "aws_secretsmanager_secret_version" "postgres_password_version" {
  secret_id = aws_secretsmanager_secret.postgres_password_secret.id
  secret_string = jsonencode({
    password = random_password.postgres_password.result
  })
  depends_on = [aws_secretsmanager_secret.postgres_password_secret]
}

resource "random_password" "postgres_password" {
  length           = var.password_length
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?" # NB cannot contain /'"@
}

# Create PostgreSQL RDS Instance
resource "aws_db_instance" "postgresql_instance" {
  identifier             = "${var.environment}-postgres-instance"
  allocated_storage      = var.allocated_storage
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  db_name                = var.db_name
  username               = var.db_username
  password               = aws_secretsmanager_secret_version.postgres_password_version.secret_string # Use the variable
  vpc_security_group_ids = [aws_security_group.postgres_sg.id]                                       # Use the security group ID from the module
  db_subnet_group_name   = var.db_subnet_group_name                                                  # Use the name
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az
  availability_zone      = var.multi_az ? null : var.availability_zones[0]
  tags = {
    Name        = "${var.environment}-postgres-instance"
    Environment = var.environment
  }
  depends_on          = [aws_secretsmanager_secret_version.postgres_password_version] #  Make secret dependency explicit
  storage_type        = var.storage_type
  storage_throughput  = var.storage_throughput
  storage_encrypted   = var.storage_encrypted
  kms_key_id          = var.kms_key_id
  replicate_source_db = var.replicate_source_db
  replica_mode        = var.replica_mode
  skip_final_snapshot = var.skip_final_snapshot
}

# Create DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = var.db_subnet_group_name
  subnet_ids  = var.db_subnet_ids
  description = "Subnet group for RDS instance"
  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
  depends_on = [aws_db_instance.postgresql_instance] # Add the dependency here
}

# IAM Role for RDS Proxy
resource "aws_iam_role" "rds_proxy_role" {
  name = "${var.environment}-rds-proxy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for RDS Proxy
resource "aws_iam_policy" "rds_proxy_policy" {
  name = "${var.environment}-rds-proxy-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "secretsmanager:GetSecretValue",
        "rds-db:connect"
      ],
      Effect = "Allow"
      Resource = [
        aws_secretsmanager_secret.postgres_password_secret.arn,
        "arn:aws:rds-db:*:*:dbuser:${var.environment}-postgres-instance/*" # Adjust as needed
      ]
    }]
  })
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "rds_proxy_role_policy_attachment" {
  role       = aws_iam_role.rds_proxy_role.name # changed from role_arn to role.name
  policy_arn = aws_iam_policy.rds_proxy_policy.arn
}

# Create RDS Proxy if enabled
resource "aws_db_proxy" "postgres_proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name                   = var.proxy_name
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.rds_proxy_role.arn
  vpc_security_group_ids = [aws_security_group.postgres_sg.id] # Use the security group ID from the module
  vpc_subnet_ids         = var.db_subnet_ids

  auth {
    auth_scheme = "SECRETS"
    secret_arn  = aws_secretsmanager_secret.postgres_password_secret.arn
    username    = var.db_username
  }

  depends_on = [aws_db_instance.postgresql_instance, aws_db_subnet_group.db_subnet_group, aws_security_group.postgres_sg]
}
