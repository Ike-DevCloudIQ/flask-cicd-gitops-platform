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
# Jenkins Master Security Group
# Lives in the public subnet (eu-west-1a)
# ──────────────────────────────────────────
resource "aws_security_group" "jenkins_master" {
  name        = "${local.name_prefix}-jenkins-master-sg"
  description = "Jenkins master: SSH from your IP, Jenkins UI from internet"
  vpc_id      = var.vpc_id

  # SSH — only from your IP (never open to 0.0.0.0/0)
  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip_cidr]
  }

  # Jenkins web UI
  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS for webhooks and plugin downloads
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Full outbound — master needs to reach Docker Hub, PyPI, GitHub
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-jenkins-master-sg"
    Role = "jenkins-master"
  })
}

# ──────────────────────────────────────────
# Jenkins Slave Security Group
# Lives in the private subnet (eu-west-1b)
# ──────────────────────────────────────────
resource "aws_security_group" "jenkins_slave" {
  name        = "${local.name_prefix}-jenkins-slave-sg"
  description = "Jenkins slave: SSH only from master, all egress via NAT"
  vpc_id      = var.vpc_id

  # SSH only from the master SG — not from the internet
  ingress {
    description     = "SSH from Jenkins master only"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_master.id]
  }

  # Jenkins JNLP agent port (master ↔ slave agent communication)
  ingress {
    description     = "JNLP agent from master"
    from_port       = 50000
    to_port         = 50000
    protocol        = "tcp"
    security_groups = [aws_security_group.jenkins_master.id]
  }

  # Full outbound via NAT gateway — slave needs Docker, pip, git
  egress {
    description = "All outbound via NAT"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-jenkins-slave-sg"
    Role = "jenkins-slave"
  })
}
