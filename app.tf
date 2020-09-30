resource "aws_security_group" "internal" {
  name        = "internal"
  description = "Allow all internal traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [ingress]
  }

  tags = map(
    "Name", "internal",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}
