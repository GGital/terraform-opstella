variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "opstella-local"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "terraform_version" {
  description = "Terraform version"
  type        = string
  default     = "1.5.7"
}

variable "output_directory" {
  description = "Directory for terraform outputs"
  type        = string
  default     = "${path.module}/../../outputs"
}

variable "approval_service_port" {
  description = "Port for approval service"
  type        = number
  default     = 8000
}

variable "approval_service_url" {
  description = "Base URL of the approval service"
  type        = string
  default     = "http://localhost:8000"
}

variable "pipeline_orchestrator_entrypoint" {
  description = "Entrypoint for pipeline orchestrator"
  type        = string
  default     = "run_local_pipeline.py"
}
