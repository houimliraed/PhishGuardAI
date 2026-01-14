from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter()

class ExtractRequest(BaseModel):
    source: str = Field(..., min_length=1)

@router.post("/extract")
async def extract_data(request: ExtractRequest):
    if not request.source or request.source.strip() == "":
        raise HTTPException(status_code=422, detail="Source cannot be empty")
    
    return {
        "source": request.source,
        "status": "extracted",
        "data": {}
    }