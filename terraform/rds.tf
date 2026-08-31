# ---------------------------------------------------------
# RDS Subnet Group
# ---------------------------------------------------------

resource "aws_db_subnet_group" "postgres" {
  name = "eightbyte-postgres-subnet-group"
  subnet_ids = [
    aws_subnet.private_app.id,
    aws_subnet.private_db.id
  ]

  tags = {
    Name = "eightbyte-postgres-subnet-group"
  }
}

# ---------------------------------------------------------
# PostgreSQL RDS Instance
# ---------------------------------------------------------

resource "aws_db_instance" "postgres" {
  identifier = "db-${var.project_name}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  db_subnet_group_name = aws_db_subnet_group.postgres.name

  vpc_security_group_ids = [
    aws_security_group.database.id
  ]

  publicly_accessible = false

  multi_az = false

  backup_retention_period = 0

  skip_final_snapshot = true

  deletion_protection = false

  apply_immediately = true

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
    Role = "database"
  }
}