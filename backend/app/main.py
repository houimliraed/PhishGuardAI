from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api import predict, analytics, extract, health, user

app = FastAPI(
    title="PhishGuard AI API",
    description="API for phishing URL detection",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(predict.router, prefix="", tags=["prediction"])
app.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
app.include_router(extract.router, prefix="/extract", tags=["extract"])
app.include_router(health.router, prefix="/health", tags=["health"])
app.include_router(user.router, prefix="/user", tags=["user"])

@app.get("/")
async def root():
    return {
        "message": "Welcome to PhishGuard AI API",
        "version": "1.0.0",
        "docs": "/docs"
    }