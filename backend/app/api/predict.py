from fastapi import APIRouter
from app.schemas.url_schema import UrlRequest
from app.core.predict import predict_url

router = APIRouter()

@router.post("/predict")
def predict(request: UrlRequest):
    return predict_url(request.url)
