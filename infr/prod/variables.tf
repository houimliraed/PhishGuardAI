variable "prefix" {
  description = "Prefix for resource names"
  default     = "dsoml"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "DevSecOps-ML"
}

variable "contact" {
  description = "Contact information for tagging resources"
  default     = "houimli@kubelab.io"
}

variable "ecr_app_image" {
  description = "ECR image URL for the backend application"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

