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
