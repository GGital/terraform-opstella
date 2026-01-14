# Opstella Terraform Pipeline

Production-ready Terraform infrastructure pipeline with GitHub Actions automation, including infrastructure-as-code validation, security scanning, and gated approval workflow.

## 📋 Project Structure

```
terraform-opstella/
├── .github/
│   └── workflows/
│       ├── pipeline-caller.yml         # Main pipeline orchestrator
│       ├── before-gate.yml             # Pre-approval validation stages
│       ├── gate-approval.yml           # Approval gate with API integration
│       └── after-gate.yml              # Post-approval apply stage
├── terraform/
│   ├── main.tf                         # Provider configuration
│   ├── infrastructure.tf               # Infrastructure resources
│   └── outputs.tf                      # Output definitions
├── mock-setup/
│   ├── fastapi-approval-service/       # FastAPI approval mock service
│   ├── requirements.txt                # Python dependencies
│   └── README.md                       # Mock setup documentation
└── README.md                           # This file
```

## 🚀 Pipeline Overview

The pipeline automates Terraform infrastructure deployment with three main stages:

### Stage 1: Before Gate (Pre-Approval Validation)
Automated validation and planning stage:
- **Terraform Format Check** - Ensure code style compliance
- **Terraform Validate** - Syntax and configuration validation
- **Terraform Lint** - Static code analysis with tflint
- **Trivy IaC Scan** - Security vulnerability scanning
- **Terraform Plan** - Generate and save infrastructure changes plan

### Stage 2: Gate Approval (Manual Review)
Requires approval before applying changes:
- Calls approval API endpoint
- Waits for approval decision
- Pipeline fails if not approved

### Stage 3: After Gate (Apply Changes)
Applies approved infrastructure changes:
- **Terraform Apply** - Deploy infrastructure to target environment

## 📊 Workflow Diagram

```
GitHub Push to main
        ↓
┌─────────────────────┐
│  Before Gate Phase  │
├─────────────────────┤
│ ✓ Format Check      │
│ ✓ Validate          │
│ ✓ Lint              │
│ ✓ Security Scan     │
│ ✓ Plan              │
└─────────────────────┘
        ↓
┌─────────────────────┐
│ Gate Approval Phase │
├─────────────────────┤
│ 🔔 API Call         │
│ ⏳ Wait for Approval │
│ ✓ Proceed if OK     │
└─────────────────────┘
        ↓
┌─────────────────────┐
│ After Gate Phase    │
├─────────────────────┤
│ ✓ Terraform Apply   │
│ ✓ Deploy            │
└─────────────────────┘
```

## 🔐 Approval Workflow

The pipeline uses an API-based approval gate:

1. **Before Gate** generates a Terraform plan and uploads artifacts
2. **Gate Approval** calls an API endpoint to check approval status
3. API must return: `{"approval_status": "approved"}`
4. If approved, pipeline proceeds to apply
5. If rejected or pending, pipeline exits with error

### Approval API Endpoint

The workflow expects an HTTP GET endpoint that returns:

```json
{
  "approval_status": "approved|rejected|pending",
  "pipeline_id": "...",
  "timestamp": "2024-01-15T14:30:23.456789",
  "message": "..."
}
```

Configure endpoint via GitHub Actions secrets:
```yaml
inputs:
  api_endpoint:
    description: "The API endpoint to call for gate approval"
    required: true
    type: string
```

## 🧪 Testing with FastAPI Mock Service

For local development and testing, a FastAPI-based approval service mock is provided:

### Quick Start

**Terminal 1 - Start the Approval Service:**
```bash
cd mock-setup/fastapi-approval-service
pip install -r requirements.txt
python main.py
```

Service runs on `http://localhost:8000`

**Terminal 2 - Test the API:**
```bash
# Check service health
curl http://localhost:8000/health

# Submit approval request
curl -X POST http://localhost:8000/approval/test-pipeline \
  -H "Content-Type: application/json" \
  -d '{"pipeline_id": "test-pipeline"}'

# Approve pipeline
curl -X PUT http://localhost:8000/approval/test-pipeline/approve

# Check approval status
curl http://localhost:8000/approval/test-pipeline

# List all approvals
curl http://localhost:8000/approvals
```

### FastAPI Service Features

- **Health Check**: `GET /health`
- **Check Status**: `GET /approval/{pipeline_id}`
- **Submit Request**: `POST /approval/{pipeline_id}`
- **Approve**: `PUT /approval/{pipeline_id}/approve`
- **Reject**: `PUT /approval/{pipeline_id}/reject`
- **List All**: `GET /approvals`
- **Delete**: `DELETE /approval/{pipeline_id}`

### Service Configuration

The service stores approval records in JSON format:

```python
approval_data/
└── approvals.json
```

Example record:
```json
{
  "test-pipeline": {
    "pipeline_id": "test-pipeline",
    "status": "approved",
    "description": "Testing approval workflow",
    "terraform_plan": null,
    "created_at": "2024-01-15T14:30:22.123456",
    "updated_at": "2024-01-15T14:30:25.789123"
  }
}
```

## 🔧 Setup Instructions

### Prerequisites

- **Terraform** >= 1.5.7
- **Git** (for version control)
- **GitHub Account** with repository access
- **Python** >= 3.8 (for mock service testing)

### 1. Install Terraform

**Windows (Chocolatey):**
```powershell
choco install terraform -y
terraform version
```

**macOS (Homebrew):**
```bash
brew install terraform
terraform version
```

**Linux:**
```bash
wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
unzip terraform_1.5.7_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### 2. Configure GitHub Secrets

The pipeline requires these secrets in your GitHub repository:

```
Settings → Secrets and variables → Actions → New repository secret
```

Required secrets:
- `APPROVAL_API_ENDPOINT` - Your approval API URL
- `GITHUB_TOKEN` - (auto-provided by GitHub)

Optional secrets (for remote backends):
- `TF_VAR_aws_access_key_id` - AWS credentials
- `TF_VAR_aws_secret_access_key` - AWS credentials
- Other Terraform variable values

### 3. Terraform Configuration

Update `terraform/main.tf` with your provider:

```hcl
terraform {
  required_version = ">= 1.5.7"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### 4. Create Terraform Variables

Create `terraform/variables.tf`:

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
```

### 5. Define Resources

Update `terraform/infrastructure.tf` with your resources:

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "OpstellaInstance"
  }
}
```

## 📝 Workflow Configuration

### pipeline-caller.yml (Main Orchestrator)

Triggered on push to main branch:

```yaml
on:
  push:
    branches:
      - main
```

### before-gate.yml (Validation)

Customizable inputs:

```yaml
inputs:
  trivy_iac_report_filename:
    default: "trivy-iac-report.json"
  terraform_plan_output_filename:
    default: "terraform-plan-output.json"
  report_retention_days:
    default: 7
```

### gate-approval.yml (Approval Gate)

Requires API endpoint configuration:

```yaml
inputs:
  api_endpoint:
    required: true
    type: string
```

Pass via caller:
```yaml
gate-approval-pipeline:
  uses: ./.github/workflows/gate-approval.yml
  with:
    api_endpoint: ${{ secrets.APPROVAL_API_ENDPOINT }}
```

## 🧪 Testing Workflow

### Test with Mock Service

1. **Start mock approval service:**
   ```bash
   cd mock-setup/fastapi-approval-service
   python main.py
   ```

2. **Manually trigger workflow:**
   - Go to GitHub Actions tab
   - Select "Opstella Terraform Pipeline Caller"
   - Click "Run workflow"
   - Workflow calls `http://localhost:8000/approval/...`
   - Service auto-approves for testing

3. **Monitor workflow:**
   - Check GitHub Actions logs
   - View artifacts (plan output, reports)
   - Verify approval API calls

### Test Individual Stages

**Test format and validation:**
```bash
cd terraform
terraform fmt -check -recursive
terraform init
terraform validate
```

**Test plan:**
```bash
cd terraform
terraform plan -out=tfplan.binary
terraform show -json tfplan.binary > plan.json
```

**Test with custom approval endpoint:**
Update `.github/workflows/gate-approval.yml`:
```yaml
- name: Awaiting Response from API
  run: |
    curl -s -X GET "${{ inputs.api_endpoint }}"
```

## 📊 Artifact Outputs

The pipeline generates these artifacts:

- **trivy-iac-report.json** - Security scanning results
- **terraform-plan-output.json** - Infrastructure change plan
- **terraform.tfstate** - Terraform state file (stored locally or remote)
- **terraform.tfstate.backup** - State backup

Access artifacts:
1. Go to workflow run
2. Click "Artifacts" section
3. Download relevant artifact

## 🔍 Troubleshooting

### Pipeline: "API endpoint not responding"

**Solution:** Ensure approval service is running and accessible

```bash
# Check if service is running
curl http://localhost:8000/health

# Check endpoint configuration
# Verify APPROVAL_API_ENDPOINT secret in GitHub
```

### Terraform: "Permission denied" on apply

**Solution:** Verify provider credentials

```bash
# Check Terraform can access cloud provider
terraform init
terraform plan

# Verify secrets are set in GitHub
```

### Workflow: "Approval status not approved"

**Solution:** Check approval API response

```bash
# Get approval status
curl http://localhost:8000/approvals

# Manually approve
curl -X PUT http://localhost:8000/approval/{pipeline-id}/approve
```

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Trivy Vulnerability Scanner](https://github.com/aquasecurity/trivy)

## 🤝 Contributing

To extend the pipeline:

1. Update workflow files in `.github/workflows/`
2. Add Terraform resources in `terraform/`
3. Test locally with mock service before pushing
4. Create pull request with changes

## 📄 License

This project is provided as-is for infrastructure automation purposes.

---

**Last Updated:** January 2024  
**Version:** 1.0.0  
**Terraform Version:** 1.5.7
