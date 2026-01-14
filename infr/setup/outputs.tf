
output "cd_user_access_key_id" {
  value       = aws_iam_access_key.cd.id
  description = "The access key id for the cd user"
}

output "cd_user_access_key_secret" {
  value       = aws_iam_access_key.cd.secret
  description = "The access key secret for the cd user"
  sensitive   = true
}

# outputs
output "ecr_backend_repo_url" {
  value       = aws_ecr_repository.devopsml_backend.repository_url
  description = "The URL of the ECR repository for the backend"
}
output "ecr_frontend_repo_url" {
  value       = aws_ecr_repository.devopsml_frontend.repository_url
  description = "The URL of the ECR repository for the frontend"
}
