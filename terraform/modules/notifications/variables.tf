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

variable "alert_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

variable "master_instance_id" {
  description = "EC2 instance ID of Jenkins master for CloudWatch alarms"
  type        = string
}

variable "slave_instance_id" {
  description = "EC2 instance ID of Jenkins slave for CloudWatch alarms"
  type        = string
}
