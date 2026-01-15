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

output "approval_service_url" {
  description = "URL of the approval service"
  value       = var.approval_service_url
}

output "pipeline_config" {
  description = "Local pipeline configuration"
  value = {
    orchestrator = var.pipeline_orchestrator_entrypoint
    approval_api = "${var.approval_service_url}/approval"
  }
}
