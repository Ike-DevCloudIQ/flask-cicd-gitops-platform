variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "flask-cicd-gitops-platform"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "owner" {
  description = "Owner tag value"
  type        = string
  default     = "Ike-DevCloudIQ"
}