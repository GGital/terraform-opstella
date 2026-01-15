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
  description = "Path for terraform output"
  type = string
  default = "."
}