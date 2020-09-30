resource "aws_db_subnet_group" "private" {
  name       = "private-${var.namespace}-${var.environment}"
  subnet_ids = var.private_subnets

  tags = map(
    "Name", "private",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

resource "aws_db_instance" "backend_postgres" {
  identifier             = "${var.namespace}-${var.environment}"
  name                   = "${var.namespace}${var.environment}"
  instance_class         = var.postgres_instance_class
  allocated_storage      = var.postgres_storage
  engine                 = "postgres"
  username               = "${var.namespace}${var.environment}"
  password               = var.rds_password
  storage_encrypted      = true
  kms_key_id             = module.kms_key.key_arn
  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [aws_security_group.internal.id]

  skip_final_snapshot = true
  deletion_protection = true

  lifecycle {
    ignore_changes = [password]
  }

  tags = map(
    "Name", "backend_postgres",
    "workload-type", "other",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}
