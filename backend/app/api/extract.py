from fastapi import APIRouter
from app.schemas.extract_schema import ExtractRequest
from app.core.extractor import extract_data

router = APIRouter()

@router.post("/extract")
def extract(request: ExtractRequest):
    return extract_data(request.source)