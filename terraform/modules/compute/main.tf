locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }
}

# ──────────────────────────────────────────
# Latest Amazon Linux 2023 AMI
# Automatically resolves the correct AMI per region
# ──────────────────────────────────────────
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ──────────────────────────────────────────
# IAM role for EC2 (CloudWatch + SSM access)
# Allows nodes to push metrics and be managed
# without opening SSH to 0.0.0.0/0
# ──────────────────────────────────────────
resource "aws_iam_role" "jenkins_ec2" {
  name = "${local.name_prefix}-jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.jenkins_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.jenkins_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins_ec2" {
  name = "${local.name_prefix}-jenkins-ec2-profile"
  role = aws_iam_role.jenkins_ec2.name
  tags = local.common_tags
}

# ──────────────────────────────────────────
# Jenkins Master EC2
# Public subnet / eu-west-1a
# ──────────────────────────────────────────
resource "aws_instance" "jenkins_master" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.master_sg_id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins_ec2.name

  # Disable accidental termination in dev — easy to override
  disable_api_termination = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  # Minimal bootstrap — Ansible will do the heavy lifting
  user_data = <<-EOF
    #!/bin/bash
    set -e
    yum update -y
    hostnamectl set-hostname jenkins-master
    echo "Jenkins master bootstrap complete" >> /var/log/bootstrap.log
  EOF

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-jenkins-master"
    Role = "jenkins-master"
  })
}

# ──────────────────────────────────────────
# Jenkins Slave EC2
# Private subnet / eu-west-1b
# ──────────────────────────────────────────
resource "aws_instance" "jenkins_slave" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.slave_sg_id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.jenkins_ec2.name

  disable_api_termination = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e
    yum update -y
    hostnamectl set-hostname jenkins-slave
    echo "Jenkins slave bootstrap complete" >> /var/log/bootstrap.log
  EOF

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-jenkins-slave"
    Role = "jenkins-slave"
  })
}
