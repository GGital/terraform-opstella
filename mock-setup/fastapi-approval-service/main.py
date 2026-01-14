"""
FastAPI Mock Approval Service
Simulates the gate approval workflow step for local testing
"""

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from enum import Enum
import json
import os
from pathlib import Path
from typing import Optional
from datetime import datetime

app = FastAPI(title="Opstella Gate Approval Service", version="1.0.0")

# Create data directory for persistence
DATA_DIR = Path("approval_data")
DATA_DIR.mkdir(exist_ok=True)
APPROVALS_FILE = DATA_DIR / "approvals.json"


class ApprovalStatus(str, Enum):
    """Approval status enumeration"""
    APPROVED = "approved"
    REJECTED = "rejected"
    PENDING = "pending"


class ApprovalRequest(BaseModel):
    """Model for approval request"""
    pipeline_id: str
    description: Optional[str] = None
    terraform_plan: Optional[str] = None


class ApprovalResponse(BaseModel):
    """Model for approval response"""
    approval_status: ApprovalStatus
    pipeline_id: str
    timestamp: str
    message: str


class ApprovalRecord(BaseModel):
    """Model for storing approval records"""
    pipeline_id: str
    status: ApprovalStatus
    description: Optional[str] = None
    terraform_plan: Optional[str] = None
    created_at: str
    updated_at: str


def load_approvals() -> dict:
    """Load approvals from file"""
    if APPROVALS_FILE.exists():
        with open(APPROVALS_FILE, 'r') as f:
            return json.load(f)
    return {}


def save_approvals(approvals: dict):
    """Save approvals to file"""
    with open(APPROVALS_FILE, 'w') as f:
        json.dump(approvals, f, indent=2)


@app.on_event("startup")
async def startup_event():
    """Initialize data on startup"""
    if not APPROVALS_FILE.exists():
        save_approvals({})
    print("FastAPI Approval Service started")


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "Approval Service"}


@app.get("/approval/{pipeline_id}")
async def check_approval(pipeline_id: str) -> ApprovalResponse:
    """
    Check approval status for a pipeline
    
    Returns approval status with a fixed response for testing.
    In a real system, this would check against a database/approval system.
    """
    approvals = load_approvals()
    
    if pipeline_id not in approvals:
        # Default to pending for new pipelines
        return ApprovalResponse(
            approval_status=ApprovalStatus.PENDING,
            pipeline_id=pipeline_id,
            timestamp=datetime.now().isoformat(),
            message="Approval pending - awaiting manual review"
        )
    
    record = approvals[pipeline_id]
    return ApprovalResponse(
        approval_status=record["status"],
        pipeline_id=pipeline_id,
        timestamp=record["updated_at"],
        message=f"Pipeline {record['status']} for review"
    )


@app.post("/approval/{pipeline_id}")
async def request_approval(pipeline_id: str, request: ApprovalRequest) -> ApprovalResponse:
    """
    Submit approval request for a pipeline
    """
    approvals = load_approvals()
    
    approval_record = ApprovalRecord(
        pipeline_id=pipeline_id,
        status=ApprovalStatus.PENDING,
        description=request.description,
        terraform_plan=request.terraform_plan,
        created_at=datetime.now().isoformat(),
        updated_at=datetime.now().isoformat()
    )
    
    approvals[pipeline_id] = approval_record.dict()
    save_approvals(approvals)
    
    return ApprovalResponse(
        approval_status=ApprovalStatus.PENDING,
        pipeline_id=pipeline_id,
        timestamp=approval_record.updated_at,
        message="Approval request submitted successfully"
    )


@app.put("/approval/{pipeline_id}/approve")
async def approve_pipeline(pipeline_id: str) -> ApprovalResponse:
    """
    Approve a pipeline (manual override for testing)
    """
    approvals = load_approvals()
    
    if pipeline_id not in approvals:
        raise HTTPException(
            status_code=404,
            detail=f"No approval request found for pipeline {pipeline_id}"
        )
    
    approvals[pipeline_id]["status"] = ApprovalStatus.APPROVED
    approvals[pipeline_id]["updated_at"] = datetime.now().isoformat()
    save_approvals(approvals)
    
    return ApprovalResponse(
        approval_status=ApprovalStatus.APPROVED,
        pipeline_id=pipeline_id,
        timestamp=approvals[pipeline_id]["updated_at"],
        message="Pipeline approved successfully"
    )


@app.put("/approval/{pipeline_id}/reject")
async def reject_pipeline(pipeline_id: str) -> ApprovalResponse:
    """
    Reject a pipeline (manual override for testing)
    """
    approvals = load_approvals()
    
    if pipeline_id not in approvals:
        raise HTTPException(
            status_code=404,
            detail=f"No approval request found for pipeline {pipeline_id}"
        )
    
    approvals[pipeline_id]["status"] = ApprovalStatus.REJECTED
    approvals[pipeline_id]["updated_at"] = datetime.now().isoformat()
    save_approvals(approvals)
    
    return ApprovalResponse(
        approval_status=ApprovalStatus.REJECTED,
        pipeline_id=pipeline_id,
        timestamp=approvals[pipeline_id]["updated_at"],
        message="Pipeline rejected"
    )


@app.get("/approvals")
async def list_all_approvals():
    """List all approval records"""
    approvals = load_approvals()
    return {
        "total": len(approvals),
        "approvals": approvals
    }


@app.delete("/approval/{pipeline_id}")
async def delete_approval(pipeline_id: str):
    """Delete an approval record"""
    approvals = load_approvals()
    
    if pipeline_id not in approvals:
        raise HTTPException(
            status_code=404,
            detail=f"No approval request found for pipeline {pipeline_id}"
        )
    
    del approvals[pipeline_id]
    save_approvals(approvals)
    
    return {
        "message": f"Approval record for {pipeline_id} deleted successfully"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
