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

variable "ecr_proxy_image" {
  description = "ECR image URL for the frontend (unused, for CI compatibility)"
  type        = string
  default     = ""
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

variable "frontend_domain_name" {
  description = "Domain name for frontend (leave empty to use CloudFront domain)"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 zone ID for DNS records (optional)"
  type        = string
  default     = ""
}

variable "tf_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
  default     = ""
}

