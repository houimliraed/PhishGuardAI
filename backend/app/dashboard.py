import os
import joblib
import numpy as np
import pandas as pd
import streamlit as st
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import confusion_matrix, roc_curve, auc, accuracy_score, classification_report

# ==========================
# Load model + data
# ==========================
BASE_DIR = os.path.dirname(__file__)

model_path = os.path.join(BASE_DIR, "models", "phishing_model.pkl")
scaler_path = os.path.join(BASE_DIR, "models", "scaler.pkl")
X_test_scaled_path = os.path.join(BASE_DIR, "models", "X_test_scaled.pkl")
y_test_path = os.path.join(BASE_DIR, "models", "y_test.pkl")

model = joblib.load(model_path)
scaler = joblib.load(scaler_path)
X_test_scaled = joblib.load(X_test_scaled_path)
y_test = joblib.load(y_test_path)

# Ensure y_test is a pandas Series for safe indexing
if not isinstance(y_test, pd.Series):
    y_test = pd.Series(y_test).reset_index(drop=True)

# ==========================
# Streamlit UI
# ==========================
st.set_page_config(page_title="Phishing URL Detector Dashboard", layout="wide")

st.title("🔐 Phishing URL Detection — Full Analytics Dashboard")
st.markdown("A complete dashboard to visualize model performance, correlations, and predictions.")

# ==========================
# Sidebar for manual prediction
# ==========================
st.sidebar.header("🔍 Predict a URL")

user_input = st.sidebar.text_input("Enter a URL to test:")

# --------------------------
# Feature extraction function
# --------------------------
def extract_features(url: str):
    """
    Extract exactly 10 features for the trained phishing detection model.
    The features must match the model's training features and order.
    """
    features = []
    features.append(len(url))                        # 1. URL length
    features.append(url.count("-"))                  # 2. Number of dashes
    features.append(url.count("@"))                  # 3. Number of '@'
    features.append(url.count("?"))                  # 4. Number of '?'
    features.append(url.count("="))                  # 5. Number of '='
    features.append(url.count("."))                  # 6. Number of dots
    features.append(url.count("%"))                  # 7. Number of '%'
    features.append(url.count("//"))                 # 8. Double slash
    features.append(int("https" in url))            # 9. HTTPS flag
    features.append(int(url.startswith("http://"))) # 10. Non-HTTPS flag
    return np.array(features).reshape(1, -1)

# --------------------------
# Manual URL prediction
# --------------------------
if st.sidebar.button("Predict URL") and user_input:
    try:
        features = extract_features(user_input)
        features_scaled = scaler.transform(features)
        prediction = model.predict(features_scaled)[0]
        st.sidebar.success("🟢 Legitimate URL" if prediction == 0 else "🔴 Phishing URL")
    except Exception as e:
        st.sidebar.error(f"Error: {e}. Check that your feature extraction matches training features.")

# ==========================
# TABS
# ==========================
tab1, tab2, tab3, tab4, tab5 = st.tabs([
    "📊 Metrics",
    "📈 Visualizations",
    "🔥 Correlations",
    "📉 Errors & Misclassifications",
    "🧪 Test Samples"
])

# ===================================================
# TAB 1 — METRICS
# ===================================================
with tab1:
    st.header("📊 Classification Metrics")

    y_pred = model.predict(X_test_scaled)

    accuracy = accuracy_score(y_test, y_pred)
    st.metric("Accuracy", f"{accuracy*100:.2f}%")

    st.subheader("Classification Report")
    st.text(classification_report(y_test, y_pred))

# ===================================================
# TAB 2 — VISUALIZATIONS
# ===================================================
with tab2:
    st.header("📈 Model Visualizations")

    col1, col2 = st.columns(2)

    # Confusion Matrix
    with col1:
        st.subheader("Confusion Matrix")
        cm = confusion_matrix(y_test, y_pred)
        fig, ax = plt.subplots()
        sns.heatmap(cm, annot=True, fmt="d", cmap="Blues")
        st.pyplot(fig)

    # ROC Curve
    with col2:
        st.subheader("ROC Curve")
        if hasattr(model, "predict_proba"):
            y_prob = model.predict_proba(X_test_scaled)[:, 1]
            fpr, tpr, _ = roc_curve(y_test, y_prob)
            roc_auc = auc(fpr, tpr)

            fig, ax = plt.subplots()
            ax.plot(fpr, tpr, label=f"AUC = {roc_auc:.2f}")
            ax.plot([0, 1], [0, 1], "--")
            ax.set_xlabel("False Positive Rate")
            ax.set_ylabel("True Positive Rate")
            ax.legend()
            st.pyplot(fig)
        else:
            st.warning("Model does not support probability prediction for ROC curve.")

    # Feature importance
    st.subheader("Feature Importance")
    if hasattr(model, "feature_importances_"):
        importances = model.feature_importances_
        fig, ax = plt.subplots(figsize=(10, 4))
        sns.barplot(x=importances, y=[f"F{i}" for i in range(len(importances))])
        st.pyplot(fig)
    else:
        st.warning("Model does not support feature importance.")

# ===================================================
# TAB 3 — CORRELATION MATRIX
# ===================================================
with tab3:
    st.header("🔥 Correlation Heatmap")

    df = pd.DataFrame(X_test_scaled, columns=[f"F{i}" for i in range(X_test_scaled.shape[1])])
    df["label"] = y_test

    corr = df.corr()
    fig, ax = plt.subplots(figsize=(10, 8))
    sns.heatmap(corr, cmap="coolwarm", annot=False)
    st.pyplot(fig)

# ===================================================
# TAB 4 — ERRORS
# ===================================================
with tab4:
    st.header("📉 Misclassified Samples")

    errors = np.where(y_test != y_pred)[0]
    st.write(f"Total misclassified samples: **{len(errors)}**")

    if len(errors) > 0:
        st.dataframe(df.iloc[errors].head(50))
    else:
        st.success("Perfect predictions — no misclassifications detected!")

# ===================================================
# TAB 5 — RANDOM TEST SAMPLE PREDICTIONS
# ===================================================
with tab5:
    st.header("🧪 Test Sample Checker")

    idx = st.number_input("Select test sample index:", min_value=0, max_value=len(X_test_scaled)-1)

    st.write("True Label:", y_test.iloc[idx])
    st.write("Predicted:", y_pred[idx])

    st.json({f"F{i}": float(X_test_scaled[idx][i]) for i in range(len(X_test_scaled[idx]))})
