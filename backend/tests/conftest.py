"""
Pytest configuration and fixtures.
Sets up mock ML models for testing without requiring actual model files.
"""

import pytest
import numpy as np
from unittest.mock import MagicMock, patch
import os
import sys

# Add app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Create mock objects BEFORE any imports
mock_model = MagicMock()
mock_model.predict.return_value = np.array([0])  # Default to "safe"

mock_scaler = MagicMock()
mock_scaler.transform.return_value = np.array([[0] * 10])  # Mock scaled features


def mock_joblib_load(path):
    """Mock joblib.load to return fake models."""
    if 'phishing_model' in str(path) or 'model' in str(path):
        return mock_model
    elif 'scaler' in str(path):
        return mock_scaler
    raise FileNotFoundError(f"Mock: {path} not found")


# Patch joblib.load BEFORE importing any app modules
joblib_patcher = patch('joblib.load', side_effect=mock_joblib_load)
joblib_patcher.start()


@pytest.fixture(scope="session", autouse=True)
def mock_ml_models():
    """
    Provide mock ML models for all tests.
    This fixture runs automatically for all tests in the session.
    """
    yield {
        'model': mock_model,
        'scaler': mock_scaler
    }
    # Stop the patcher when tests are done
    joblib_patcher.stop()


@pytest.fixture
def safe_prediction(mock_ml_models):
    """Configure mock model to predict 'safe' (0)."""
    mock_ml_models['model'].predict.return_value = np.array([0])
    return mock_ml_models


@pytest.fixture
def phishing_prediction(mock_ml_models):
    """Configure mock model to predict 'phishing' (1)."""
    mock_ml_models['model'].predict.return_value = np.array([1])
    return mock_ml_models
