from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr

router = APIRouter()

class UserCreate(BaseModel):
    email: EmailStr
    username: str

@router.post("/user")
async def create_user(user: UserCreate):
    return {
        "email": user.email,
        "username": user.username,
        "id": "generated-id",
        "status": "created"
    }