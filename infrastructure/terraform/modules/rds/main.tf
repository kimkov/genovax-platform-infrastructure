terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

resource "aws_db_parameter_group" "rds_pg" {
  name = "${var.env}-rds-pg"
  family = "postgres18"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name = "${var.env}-rds-parameter-group"
  }
}

resource "aws_db_instance" "primary" {
  identifier = "${var.env}-db-primary"
  engine = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  allocated_storage = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type = var.storage_type

  db_name = var.db_name
  username = var.db_username
  password = var.db_password

  parameter_group_name = aws_db_parameter_group.rds_pg.name

  # Use variables for modularity
  multi_az = var.multi_az
  network_type = var.network_type
  publicly_accessible = var.publicly_accessible
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # High Compliance & Security
  storage_encrypted = var.storage_encrypted
  kms_key_id = var.kms_key_arn
  deletion_protection = var.deletion_protection
  copy_tags_to_snapshot = var.copy_tags_to_snapshot

  # Monitoring & Performance Insights (High-Compliance Requirement)
  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = var.kms_key_arn
  performance_insights_retention_period = var.performance_insights_retention_period

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_role_arn

  # Maintenance & Backups
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  backup_retention_period = var.backup_retention_period
  backup_window = var.backup_window
  maintenance_window = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  skip_final_snapshot = var.skip_final_snapshot

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name = aws_db_subnet_group.rds.name
}

resource "aws_db_instance" "replica" {
  count = 2
  replicate_source_db = aws_db_instance.primary.identifier
  instance_class = var.instance_class
  identifier = "${var.env}-db-replica-${count.index}"

  # Replicas inherit encryption and network settings
  storage_encrypted = var.storage_encrypted
  kms_key_id = var.kms_key_arn
  network_type = var.network_type
  publicly_accessible = var.publicly_accessible
  skip_final_snapshot = true
}

resource "aws_security_group" "rds" {
  name = "${var.env}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = var.allowed_security_groups
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds" {
  name = "${var.env}-rds-subnet-group"
  subnet_ids = var.subnet_ids
}