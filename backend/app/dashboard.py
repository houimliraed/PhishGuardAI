import streamlit as st
import pandas as pd
import joblib
import re
import os
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

BASE_DIR = os.path.dirname(__file__)  # directory of dashboard.py
model_path = os.path.join(BASE_DIR, "models", "phishing_model.pkl")
scaler_path = os.path.join(BASE_DIR, "models", "scaler.pkl")

model = joblib.load(model_path)
scaler = joblib.load(scaler_path)


BASE_DIR = os.path.dirname(__file__)  # directory of dashboard.py
X_test_scaled_path = os.path.join(BASE_DIR, "models", "X_test_scaled.pkl")
y_test_path = os.path.join(BASE_DIR, "models", "y_test.pkl")

X_test_scaled = joblib.load(X_test_scaled_path)
y_test = joblib.load(y_test_path)





st.title("Phishing URL Detector 🛡️")

st.markdown("Enter a URL below to check if it's safe or phishing.")

# Input URL
url_input = st.text_input("URL:")

# Example: model evaluation visualization
st.subheader("Model Performance on Test Set")
accuracy = 0.7692  # Replace with your computed accuracy
st.write(f"**Random Forest Accuracy:** {accuracy:.2f}")

# Optionally, display confusion matrix
if st.checkbox("Show Confusion Matrix"):
    import matplotlib.pyplot as plt
    from sklearn.metrics import ConfusionMatrixDisplay
    
    # Load your test set predictions (or recalc if needed)
    # Here we assume X_test_scaled and y_test exist
    y_pred = model.predict(X_test_scaled)
    
    fig, ax = plt.subplots()
    ConfusionMatrixDisplay.from_predictions(y_test, y_pred, ax=ax, cmap="Blues")
    st.pyplot(fig)

# Function to extract features from URL
def extract_features(url):
    features = {}
    features['URL_Length'] = len(url)
    features['Num_Dots'] = url.count('.')
    features['Num_Hyphens'] = url.count('-')
    features['Num_Underscores'] = url.count('_')
    features['Has_At'] = 1 if '@' in url else 0
    features['Has_Tilde'] = 1 if '~' in url else 0
    features['Num_Digits'] = sum(c.isdigit() for c in url)
    features['Num_Subdomains'] = url.count('.') - 1
    features['Has_IP'] = 1 if re.match(r'(\d{1,3}\.){3}\d{1,3}', url) else 0
    features['HTTPS'] = 1 if url.startswith('https') else 0
    return pd.DataFrame([features])

# Predict on user input
if url_input:
    X_new = extract_features(url_input)
    X_scaled = scaler.transform(X_new)
    prediction = model.predict(X_scaled)[0]
    prob = model.predict_proba(X_scaled)[0][prediction]
    label = "Phishing ⚠️" if prediction == 1 else "Safe ✅"
    
    st.subheader("Prediction Result")
    st.write(f"**URL:** {url_input}")
    st.write(f"**Prediction:** {label}")
    st.write(f"**Confidence:** {prob:.2f}")
