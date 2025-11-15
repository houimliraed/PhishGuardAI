from fastapi import FastAPI
from app.api.predict import router as predict_router
from fastapi.middleware.cors import CORSMiddleware



app = FastAPI(title="AI URL finishing detector",
              version=1.0,
              description="API for testing finishing url using ML")
origins = [
    "http://localhost:3000",     
    "http://127.0.0.1:3000",
    "*"                     
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(predict_router, prefix="/api", tags=["Predict"])

@app.get("/")
def root():
    return {"message": "Phishing Detection API is running"}