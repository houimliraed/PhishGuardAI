from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_create_user_success():
    payload = {
        "email": "test@example.com",
        "username": "testuser"
    }
    response = client. post("/user", json=payload)
    assert response.status_code == 200
    assert "email" in response.json() or "id" in response.json()

def test_create_user_invalid_email():
    payload = {
        "email": "invalid-email",
        "username": "testuser"
    }
    response = client.post("/user", json=payload)
    assert response.status_code == 422  # Validation error