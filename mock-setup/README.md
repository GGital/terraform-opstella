# Opstella FastAPI Approval Service Mock

FastAPI-based mock approval service for testing the Opstella Terraform pipeline's gated approval workflow.

## Project Structure

```
mock-setup/
├── fastapi-approval-service/
│   ├── main.py                 # FastAPI approval service
│   └── requirements.txt         # Python dependencies
├── requirements.txt             # All Python dependencies
└── README.md                    # This file
```

## Prerequisites

### System Requirements
- **Terraform** >= 1.5.7
- **Python** >= 3.8
- **Git** (for version control)

### Optional Tools (for enhanced functionality)
- **tflint** - For Terraform linting
- **Trivy** - For IaC security scanning
- **curl** or **Postman** - For API testing

## Installation

### 1. Install Terraform

**Windows (using Chocolatey):**
```powershell
choco install terraform -y
```

**Windows (manual):**
- Download from: https://www.terraform.io/downloads
- Add to PATH environment variable

**Verify installation:**
```bash
terraform version
```

### 2. Install Python and Dependencies

**Install Python (if not already installed):**
- Download from: https://www.python.org/downloads/
- Choose "Add Python to PATH" during installation

**Create virtual environment (recommended):**
```bash
cd mock-setup
python -m venv venv
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate
```

**Install Python dependencies:**
```bash
pip install fastapi uvicorn pydantic requests
# Or use requirements file:
pip install -r fastapi-approval-service/requirements.txt
```

### 3. Optional - Install Additional Tools

**Install tflint:**
```bash
# Windows (using Chocolatey):
choco install tflint -y

# Or download from: https://github.com/terraform-linters/tflint/releases
```

**Install Trivy:**
```bash
# Windows (using Chocolatey):
choco install trivy -y

# Or download from: https://github.com/aquasecurity/trivy/releases
```

## Running the Service

### Start the Approval Service

```bash
cd mock-setup/fastapi-approval-service
python main.py
```

Expected output:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
FastAPI Approval Service started
```

Service will be available at `http://localhost:8000`

### Test with Approval API

**Check service health:**
```bash
curl http://localhost:8000/health
```

**Submit approval request:**
```bash
curl -X POST http://localhost:8000/approval/test-pipeline \
  -H "Content-Type: application/json" \
  -d '{"pipeline_id": "test-pipeline", "description": "Test pipeline"}'
```

**Approve a pipeline:**
```bash
curl -X PUT http://localhost:8000/approval/test-pipeline/approve
```

**Check approval status:**
```bash
curl http://localhost:8000/approval/test-pipeline
```

**List all approvals:**
```bash
curl http://localhost:8000/approvals
```

**Reject a pipeline:**
```bash
curl -X PUT http://localhost:8000/approval/test-pipeline/reject
```

**Delete approval record:**
```bash
curl -X DELETE http://localhost:8000/approval/test-pipeline
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Service health check |
| `/approval/{pipeline_id}` | GET | Check approval status |
| `/approval/{pipeline_id}` | POST | Submit approval request |
| `/approval/{pipeline_id}/approve` | PUT | Approve pipeline |
| `/approval/{pipeline_id}/reject` | PUT | Reject pipeline |
| `/approvals` | GET | List all approval records |
| `/approval/{pipeline_id}` | DELETE | Delete approval record |

### Response Format

**Approval Status Response:**
```json
{
  "approval_status": "approved|rejected|pending",
  "pipeline_id": "test-pipeline",
  "timestamp": "2024-01-15T14:30:23.456789",
  "message": "Pipeline approved successfully"
}
```

**List All Approvals Response:**
```json
{
  "total": 1,
  "approvals": {
    "test-pipeline": {
      "pipeline_id": "test-pipeline",
      "status": "approved",
      "description": "Test pipeline",
      "terraform_plan": null,
      "created_at": "2024-01-15T14:30:22.123456",
      "updated_at": "2024-01-15T14:30:25.789123"
    }
  }
}
```

## Output and Data Storage

### Data Persistence

The service stores approval records in a JSON file:

```
mock-setup/approval_data/
└── approvals.json
```

Example approval record:
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

## Testing Workflows

### Scenario 1: Test Service Availability
```bash
# In one terminal
python mock-setup/fastapi-approval-service/main.py

# In another terminal
curl http://localhost:8000/health
```

### Scenario 2: Test Approval Flow
```bash
# Submit a request
curl -X POST http://localhost:8000/approval/pipeline-001 \
  -H "Content-Type: application/json" \
  -d '{"pipeline_id": "pipeline-001"}'

# Check status (should be pending)
curl http://localhost:8000/approval/pipeline-001

# Approve it
curl -X PUT http://localhost:8000/approval/pipeline-001/approve

# Check status again (should be approved)
curl http://localhost:8000/approval/pipeline-001
```

### Scenario 3: Test Rejection
```bash
# Submit a request
curl -X POST http://localhost:8000/approval/pipeline-002 \
  -H "Content-Type: application/json" \
  -d '{"pipeline_id": "pipeline-002"}'

# Reject it
curl -X PUT http://localhost:8000/approval/pipeline-002/reject

# Check status
curl http://localhost:8000/approval/pipeline-002
```

### Scenario 4: Simulate GitHub Actions Call
```bash
# GitHub Actions will call this endpoint
RESPONSE=$(curl -s -X GET "http://localhost:8000/approval/github-pipeline" \
  -H "Accept: application/json")

# Check if approved
echo $RESPONSE | jq .approval_status
```

## Troubleshooting

### Issue: `ModuleNotFoundError: No module named 'fastapi'`
**Solution:** Install Python dependencies
```bash
pip install fastapi uvicorn pydantic requests
# Or:
pip install -r requirements.txt
```

### Issue: Port 8000 already in use
**Solution:** Change service port in `fastapi-approval-service/main.py`
```python
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
```

Then update your API calls to use port 8001:
```bash
curl http://localhost:8001/health
```

### Issue: `Connection refused` when calling service
**Solution:** Ensure service is running
```bash
# Check if service is running
curl http://localhost:8000/health

# If not, start it:
cd mock-setup/fastapi-approval-service
python main.py
```

### Issue: GitHub Actions can't reach approval service
**Solution:** Service must be publicly accessible

For local testing:
1. Use local mock service on `localhost:8000`
2. Test manually before pushing to GitHub

For production:
1. Deploy FastAPI service to cloud (AWS, Azure, GCP)
2. Update GitHub secret `APPROVAL_API_ENDPOINT` with public URL
3. Ensure service has proper CORS and authentication

## Integration with GitHub Actions

The approval service integrates with the Opstella pipeline workflow via the `gate-approval.yml` workflow.

### How It Works

1. **Pipeline Runs**: GitHub Actions triggers on push to main
2. **Before Gate Executes**: Terraform validation, linting, planning
3. **Gate Approval Called**: Workflow calls the approval API
4. **API Response Checked**: Looks for `"approval_status": "approved"`
5. **Continue or Fail**: 
   - If approved → Proceed to apply
   - If not approved → Exit with error

### Workflow Configuration

In `.github/workflows/gate-approval.yml`:

```yaml
- name: Awaiting Response from API
  run: |
    RESPONSE=$(curl -s -X GET "${{ inputs.api_endpoint }}" \
    -H "Accept: application/json")
    
    APPROVAL_STATUS=$(echo "$RESPONSE" | jq .approval_status)
    
    if [ "$APPROVAL_STATUS" != "approved" ]; then
      echo "Gate not approved. Exiting pipeline."
      exit 1
    fi
    
    echo "Gate approved. Proceeding to the next step."
```

### Setting Up Your Approval Service

For production use:

1. **Deploy FastAPI service** to cloud platform:
   - AWS Lambda / EC2
   - Azure Functions / App Service
   - Google Cloud Run
   - Heroku
   - Your own server

2. **Add authentication** (optional but recommended):
   ```python
   from fastapi.security import HTTPBearer
   
   security = HTTPBearer()
   
   @app.get("/approval/{pipeline_id}")
   async def check_approval(pipeline_id: str, credentials: HTTPAuthCredentials = Depends(security)):
       # Verify credentials
       ...
   ```

3. **Add database** instead of JSON files:
   - PostgreSQL
   - DynamoDB
   - MongoDB
   - etc.

4. **Configure GitHub Secret**:
   - Go to Settings → Secrets and variables → Actions
   - Add secret: `APPROVAL_API_ENDPOINT`
   - Value: Your deployed service URL

5. **Update pipeline caller** (`.github/workflows/pipeline-caller.yml`):
   ```yaml
   gate-approval-pipeline:
     with:
       api_endpoint: ${{ secrets.APPROVAL_API_ENDPOINT }}
   ```

## API Testing Examples

### Using curl

**Check service health:**
```bash
curl http://localhost:8000/health
```

**Submit approval request:**
```bash
curl -X POST http://localhost:8000/approval/test-pipeline-001 \
  -H "Content-Type: application/json" \
  -d '{
    "pipeline_id": "test-pipeline-001",
    "description": "Testing approval workflow"
  }'
```

**Auto-approve (for testing):**
```bash
curl -X PUT http://localhost:8000/approval/test-pipeline-001/approve
```

**Check status:**
```bash
curl http://localhost:8000/approval/test-pipeline-001
```

**List all approvals:**
```bash
curl http://localhost:8000/approvals
```

### Using Python

```python
import requests

API_URL = "http://localhost:8000"

# Check health
response = requests.get(f"{API_URL}/health")
print(response.json())

# Request approval
response = requests.post(
    f"{API_URL}/approval/my-pipeline",
    json={"pipeline_id": "my-pipeline"}
)
print(response.json())

# Approve
response = requests.put(f"{API_URL}/approval/my-pipeline/approve")
print(response.json())

# Check status
response = requests.get(f"{API_URL}/approval/my-pipeline")
print(response.json())
```

### Using Postman

1. **Import Postman Collection**:
   Create requests for each endpoint:
   - `GET` http://localhost:8000/health
   - `POST` http://localhost:8000/approval/{pipeline_id}
   - `PUT` http://localhost:8000/approval/{pipeline_id}/approve
   - `PUT` http://localhost:8000/approval/{pipeline_id}/reject
   - `GET` http://localhost:8000/approvals

2. **Save Collection** for future use

3. **Run tests** against your service

## Next Steps

1. **Configure GitHub Secrets**: Add `APPROVAL_API_ENDPOINT` to your repository
2. **Deploy Approval Service**: Host the FastAPI service or use local for testing
3. **Update Terraform**: Add your actual infrastructure resources in `../terraform/`
4. **Configure Workflow**: Update `.github/workflows/gate-approval.yml` with your API endpoint
5. **Test Pipeline**: Push to main branch and verify workflow execution

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review FastAPI documentation: https://fastapi.tiangolo.com/
3. Check GitHub Actions logs in the repository
4. Verify service is running: `curl http://localhost:8000/health`

---

**Version:** 1.0.0
**Last Updated:** January 2024
