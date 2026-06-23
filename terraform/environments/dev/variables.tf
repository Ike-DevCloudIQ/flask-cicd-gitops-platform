variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "flask-cicd-gitops-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "Ike-DevCloudIQ"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR for Jenkins master"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR for Jenkins slave"
  type        = string
  default     = "10.0.10.0/24"
}

variable "public_availability_zone" {
  description = "AZ for public subnet"
  type        = string
  default     = "eu-west-1a"
}

variable "private_availability_zone" {
  description = "AZ for private subnet"
  type        = string
  default     = "eu-west-1b"
}

variable "your_ip_cidr" {
  description = "Your public IP in CIDR notation for SSH access (e.g. 1.2.3.4/32)"
  type        = string
  # Set this in terraform.tfvars — never hardcode a real IP here
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins master and slave"
  type        = string
  default     = "t3.medium"
}

variable "alert_email" {
  description = "Email address for CloudWatch SNS alarm notifications"
  type        = string
}