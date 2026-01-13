from fastapi import APIRouter
from app.schemas.user_schema import UserRequest
from app.core.user_service import create_user

router = APIRouter()

@router.post("/user")
def create(request: UserRequest):
    return create_user(request.email, request.username)