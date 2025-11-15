from app.core.extractor import extract_features
import joblib
import os

# just making sure we get the right path
BASE_DIR = os.path.dirname(__file__)
APP_DIR = os.path.join(BASE_DIR, "..")
model_path = os.path.join(APP_DIR, "models", "phishing_model.pkl")
scaler_path = os.path.join(APP_DIR, "models", "scaler.pkl")

model = joblib.load(model_path)
scaler = joblib.load(scaler_path)

def predict_url(url: str):
    features = extract_features(url)
    features_scaled = scaler.transform(features)
    predict = model.predict(features_scaled)[0]
    
    return {
        "url":url,
        "prediction": "fishing" if predict == 1 else "safe"
    }
    

