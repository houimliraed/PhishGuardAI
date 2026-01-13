from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_extract_data_success():
    payload = {
        "source": "https://example.com/data"
    }
    response = client.post("/extract", json=payload)
    assert response.status_code == 200
    assert response.json() is not None

def test_extract_data_empty_source():
    payload = {
        "source": ""
    }
    response = client.post("/extract", json=payload)
    assert response.status_code == 422  # Validation error