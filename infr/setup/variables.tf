
variable "tf_state_bucket" {
  description = "S3 bucket name for Terraform state storage"
  default     = "devops-ml-tf-state"
}

variable "project" {
  description = "project name for tagging resources"
  default     = "DevSecOps-ML"
}

variable "contact" {
  description = "Contact information for tagging resources"
  default     = "houimli@kubelab.io"
}

