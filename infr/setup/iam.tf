
resource "aws_user" "deploy_user" {
  name = "${var.prefix}-deploy-user"
  tags = {
    Environment = terraform.workspace
    Project     = var.project
    contact     = var.contact
    ManagedBy   = "Terraform/setup"
  }
}