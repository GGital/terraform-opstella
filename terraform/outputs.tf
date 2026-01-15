output "output_directory" {
  description = "Directory where terraform outputs are stored"
  value       = var.output_directory
}

output "project_info" {
  description = "Project information"
  value = {
    project_name       = var.project_name
    environment        = var.environment
    terraform_version  = var.terraform_version
  }
}
