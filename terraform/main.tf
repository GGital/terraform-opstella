terraform {
  required_version = ">= 1.5.7"
  
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

provider "local" {}

locals {
  timestamp = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timestamp())
}

# Create output directory for artifacts
resource "local_file" "terraform_output_dir" {
  filename = "${var.output_directory}/terraform.txt"
  content = jsonencode({
    created_at  = local.timestamp
    project     = var.project_name
    environment = var.environment
  })
}

# Create infrastructure configuration file
resource "local_file" "infrastructure_config" {
  filename = "${var.output_directory}/infrastructure-config.json"
  content = jsonencode({
    project_name = var.project_name
    environment  = var.environment
    created_at   = local.timestamp
    components = {
      approval_service = {
        type    = "fastapi"
        port    = var.approval_service_port
        url     = var.approval_service_url
        health  = "${var.approval_service_url}/health"
      }
      pipeline_orchestrator = {
        type       = "python-script"
        entrypoint = var.pipeline_orchestrator_entrypoint
      }
    }
  })

  depends_on = [local_file.terraform_output_dir]
}

# Create terraform plan output
resource "local_file" "terraform_plan" {
  filename = "${var.output_directory}/terraform-plan-output.json"
  content = jsonencode({
    format_version     = "1.2"
    terraform_version  = var.terraform_version
    created_at         = local.timestamp
    project_name       = var.project_name
    environment        = var.environment
    output_directory   = var.output_directory
  })

  depends_on = [local_file.terraform_output_dir]
}
