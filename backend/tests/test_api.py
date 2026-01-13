"""
Integration tests for the FastAPI prediction endpoint.
Tests the /api/predict endpoint functionality.
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app


client = TestClient(app)


class TestPredictAPI:
    """Test suite for the /api/predict endpoint."""

    def test_predict_endpoint_exists(self):
        """Test that the /api/predict endpoint exists."""
        response = client.post(
            "/api/predict",
            json={"url": "https://example.com"}
        )

        # Should not return 404
        assert response.status_code != 404

    def test_predict_with_valid_url(self):
        """Test prediction with a valid URL."""
        response = client.post(
            "/api/predict",
            json={"url": "https://www.google.com"}
        )

        assert response.status_code == 200
        data = response.json()

        # Verify response structure
        assert "url" in data
        assert "prediction" in data
        assert data["url"] == "https://www.google.com"
        assert data["prediction"] in ["safe", "phishing"]

    def test_predict_with_http_url(self):
        """Test prediction with HTTP (non-HTTPS) URL."""
        response = client.post(
            "/api/predict",
            json={"url": "http://example.com"}
        )

        assert response.status_code == 200
        data = response.json()

        assert "prediction" in data
        assert data["prediction"] in ["safe", "phishing"]

    def test_predict_with_suspicious_url(self):
        """Test prediction with a suspicious-looking URL."""
        # URL with IP address and suspicious patterns
        response = client.post(
            "/api/predict",
            json={"url": "http://192.168.1.1/login-bank-secure@phishing.com"}
        )

        assert response.status_code == 200
        data = response.json()

        assert "prediction" in data
        # Note: actual prediction depends on model, just verify it returns something
        assert data["prediction"] in ["safe", "phishing"]

    def test_predict_missing_url_field(self):
        """Test prediction with missing 'url' field in request."""
        response = client.post(
            "/api/predict",
            json={}
        )

        # Should return 422 Unprocessable Entity (validation error)
        assert response.status_code == 422

    def test_predict_invalid_json(self):
        """Test prediction with invalid JSON payload."""
        response = client.post(
            "/api/predict",
            data="invalid json",
            headers={"Content-Type": "application/json"}
        )

        # Should return 422 (validation error)
        assert response.status_code == 422

    def test_predict_empty_url(self):
        """Test prediction with empty URL string."""
        response = client.post(
            "/api/predict",
            json={"url": ""}
        )

        # Depending on validation, might be 200 or 422
        # Just verify it doesn't crash the server
        assert response.status_code in [200, 422]

    def test_predict_url_with_special_characters(self):
        """Test prediction with URL containing special characters."""
        response = client.post(
            "/api/predict",
            json={"url": "https://example.com/path?param=value&other=123"}
        )

        assert response.status_code == 200
        data = response.json()
        assert "prediction" in data

    def test_predict_returns_original_url(self):
        """Test that the response includes the original URL."""
        test_url = "https://test-domain.com/page"
        response = client.post(
            "/api/predict",
            json={"url": test_url}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["url"] == test_url

    def test_predict_multiple_requests(self):
        """Test making multiple prediction requests sequentially."""
        urls = [
            "https://google.com",
            "https://github.com",
            "http://example.com"
        ]

        for url in urls:
            response = client.post(
                "/api/predict",
                json={"url": url}
            )

            assert response.status_code == 200
            data = response.json()
            assert data["url"] == url
            assert "prediction" in data

    def test_cors_headers_present(self):
        """Test that CORS headers are present in response."""
        response = client.post(
            "/api/predict",
            json={"url": "https://example.com"}
        )

        # Check for CORS headers
        assert "access-control-allow-origin" in response.headers

    def test_content_type_json(self):
        """Test that response content type is JSON."""
        response = client.post(
            "/api/predict",
            json={"url": "https://example.com"}
        )

        assert response.status_code == 200
        assert "application/json" in response.headers["content-type"]

    @pytest.mark.parametrize("url", [
        "https://legitimate-site.com",
        "https://www.bank-of-america.com",
        "https://secure.paypal.com",
    ])
    def test_predict_legitimate_urls(self, url):
        """Test prediction for various legitimate-looking URLs."""
        response = client.post(
            "/api/predict",
            json={"url": url}
        )

        assert response.status_code == 200
        data = response.json()
        assert "prediction" in data

    @pytest.mark.parametrize("url", [
        "http://192.168.0.1/~admin",
        "http://phishing-site123.tk",
        "http://secure-login@fake-bank.com",
    ])
    def test_predict_suspicious_urls(self, url):
        """Test prediction for various suspicious-looking URLs."""
        response = client.post(
            "/api/predict",
            json={"url": url}
        )

        assert response.status_code == 200
        data = response.json()
        assert "prediction" in data


class TestRootEndpoint:
    """Test suite for root and health check endpoints."""

    def test_root_endpoint(self):
        """Test that root endpoint doesn't crash."""
        response = client.get("/")

        # Should not be 500
        assert response.status_code != 500

    def test_docs_endpoint_exists(self):
        """Test that OpenAPI docs endpoint exists."""
        response = client.get("/docs")

        # Docs should be accessible
        assert response.status_code == 200

    def test_openapi_json_exists(self):
        """Test that OpenAPI JSON schema is accessible."""
        response = client.get("/openapi.json")

        assert response.status_code == 200
        assert "application/json" in response.headers["content-type"]
