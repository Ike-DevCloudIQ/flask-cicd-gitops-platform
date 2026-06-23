variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "owner" {
  description = "Owner tag"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for Jenkins master"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID for Jenkins slave"
  type        = string
}

variable "master_sg_id" {
  description = "Security group ID for Jenkins master"
  type        = string
}

variable "slave_sg_id" {
  description = "Security group ID for Jenkins slave"
  type        = string
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins nodes"
  type        = string
  default     = "t3.medium"
}
