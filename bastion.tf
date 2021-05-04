
# This will be replaced with VPN IP address or SG in the future
data "http" "bastion_allow_ip" {
  url = "https://ifconfig.me"
}


resource "aws_security_group" "bastion" {
  count       = var.enable_bastion == "" ? 1 : 0
  name        = "bastion"
  description = "Allow SSH access for debugging"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 222
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.http.bastion_allow_ip.body}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = map(
    "Name", "internal",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )

}

data "aws_ami" "ubuntu" {
  most_recent = true 
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "bastion" {
  count           = var.enable_bastion == "" ? 1 : 0

  ami             = data.aws_ami.ubuntu.id 
  instance_type   = "t3.micro"
  subnet_id       = var.public_subnets[0]
  security_groups = [aws_security_group.bastion[0].id]
 
  tags = {
    Name = "Bastion"
  }

}
