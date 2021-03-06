data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  owners = ["amazon"]
}

# Provision an AWS instance for interacting with CloudHSM
resource "aws_instance" "hsm_client" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.medium"

  subnet_id              = module.vpc.public_subnets.0
  vpc_security_group_ids = [aws_security_group.allow_egress.id,aws_cloudhsm_v2_cluster.hsm_cluster.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.workload_instance_profile.name

  tags = {
    Name        = "hsm_client"
    Environment = var.environment
  }
}

resource "aws_security_group" "allow_egress" {
  name        = "allow-egress"
  description = "Allow egress outbound traffic"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "allow-egress"
    Environment = var.environment
  }
}
