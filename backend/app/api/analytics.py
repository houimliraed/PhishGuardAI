from fastapi import APIRouter
from app.schemas.analytics_schema import AnalyticsRequest
from app.core.analytics_service import get_analytics

router = APIRouter()

@router.post("/analytics")
def analytics(request: AnalyticsRequest):
    return get_analytics(request.start_date, request.end_date)