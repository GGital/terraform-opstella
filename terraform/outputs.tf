output "output_directory" {
  description = "Directory where terraform outputs are stored"
  value       = "${path.module}/../../outputs"
}

output "project_info" {
  description = "Project information"
  value = {
    project_name = "opstella-local"
    environment  = "dev"
    terraform_version = "1.5.7"
  }
}

output "approval_service_url" {
  description = "URL of the approval service"
  value       = "http://localhost:8000"
}

output "pipeline_config" {
  description = "Local pipeline configuration"
  value = {
    orchestrator = "run_local_pipeline.py"
    approval_api = "http://localhost:8000/approval"
  }
}
