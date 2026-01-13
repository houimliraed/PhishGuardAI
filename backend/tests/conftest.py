"""
Pytest configuration and fixtures.
Sets up mock ML models for testing without requiring actual model files.
"""

import pytest
import joblib
import numpy as np
from unittest.mock import MagicMock, patch
import os
import sys

# Add app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


@pytest.fixture(scope="session", autouse=True)
def mock_ml_models():
    """
    Mock the ML models to avoid requiring actual model files during testing.
    This fixture runs automatically for all tests in the session.
    """
    # Create mock model
    mock_model = MagicMock()
    mock_model.predict.return_value = np.array([0])  # Default to "safe"

    # Create mock scaler
    mock_scaler = MagicMock()
    mock_scaler.transform.return_value = np.array([[0] * 10])  # Mock scaled features

    # Patch joblib.load to return our mocks
    with patch('joblib.load') as mock_load:
        def load_side_effect(path):
            if 'model' in path:
                return mock_model
            elif 'scaler' in path:
                return mock_scaler
            raise FileNotFoundError(f"Mock: {path} not found")

        mock_load.side_effect = load_side_effect

        # Import app.core.predict to trigger model loading with mocks
        # This needs to happen AFTER we set up the patches
        import app.core.predict

        # Replace the module-level model and scaler with our mocks
        app.core.predict.model = mock_model
        app.core.predict.scaler = mock_scaler

        yield {
            'model': mock_model,
            'scaler': mock_scaler
        }


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
