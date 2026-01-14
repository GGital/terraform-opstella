# Local variables configuration
locals {
  project_name = "opstella-local"
  environment  = "dev"
  timestamp    = formatdate("YYYY-MM-DD'T'hh:mm:ss'Z'", timestamp())
}

# Create output directory for artifacts
resource "local_file" "terraform_output_dir" {
  filename = "${path.module}/../../outputs/terraform.txt"
  content = jsonencode({
    created_at = local.timestamp
    project    = local.project_name
    environment = local.environment
  })

  depends_on = [null_resource.create_output_dir]
}

# Create directories for terraform outputs
resource "null_resource" "create_output_dir" {
  provisioners {
    local-exec {
      command = "mkdir -p ${path.module}/../../outputs"
    }
  }
}

# Create sample infrastructure configuration file
resource "local_file" "infrastructure_config" {
  filename = "${path.module}/../../outputs/infrastructure-config.json"
  content = jsonencode({
    project_name = local.project_name
    environment  = local.environment
    created_at   = local.timestamp
    components = {
      approval_service = {
        type    = "fastapi"
        port    = 8000
        url     = "http://localhost:8000"
        health  = "http://localhost:8000/health"
      }
      pipeline_orchestrator = {
        type       = "python-script"
        entrypoint = "run_local_pipeline.py"
      }
    }
  })

  depends_on = [null_resource.create_output_dir]
}

# Create mock terraform plan output
resource "local_file" "terraform_plan" {
  filename = "${path.module}/../../outputs/terraform-plan-output.json"
  content = jsonencode({
    format_version = "1.2"
    terraform_version = "1.5.7"
    variables = {
      environment = {
        value = local.environment
      }
    }
    resource_changes = [
      {
        address = "local_file.terraform_output_dir"
        mode    = "managed"
        type    = "local_file"
        name    = "terraform_output_dir"
        actions = ["create"]
        change = {
          actions = ["create"]
          before  = null
          after = {
            content  = "configuration output"
            filename = "${path.module}/../../outputs/terraform.txt"
          }
          after_unknown = {}
        }
      }
    ]
    output_changes = {
      output_directory = {
        actions = ["create"]
        after   = "${path.module}/../../outputs"
      }
    }
    prior_state = null
  })

  depends_on = [local_file.terraform_output_dir]
}
