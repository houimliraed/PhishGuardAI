from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from datetime import date

router = APIRouter()

class AnalyticsRequest(BaseModel):
    start_date: date
    end_date: date

@router.post("/analytics")
async def get_analytics(request: AnalyticsRequest):
    if request.start_date > request.end_date:
        raise HTTPException(status_code=400, detail="Invalid date range")
    
    return {
        "start_date": request.start_date,
        "end_date": request.end_date,
        "total_predictions": 0,
        "phishing_detected": 0,
        "legitimate_detected": 0
    }

@router.get("/analytics/summary")
async def get_analytics_summary():
    return {
        "total_predictions": 0,
        "phishing_detected": 0,
        "legitimate_detected": 0,
        "accuracy": 0.0
    }