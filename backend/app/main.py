from fastapi import FastAPI
from app.api.predict import router as predict_router
from fastapi.middleware.cors import CORSMiddleware



app = FastAPI(
    title="AI URL phishing detector",
    version="1.0",
    description="API for testing phishing URLs using ML",
)

# Allow known dev origins (Vite defaults to 5173) without wildcard when using credentials
origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(predict_router, prefix="/api", tags=["Predict"])

@app.get("/")
def root():
    return {"message": "Phishing Detection API is running"}