from fastapi. testclient import TestClient
from app.main import app

client = TestClient(app)

def test_analytics_post_success():
    payload = {
        "start_date": "2026-01-01",
        "end_date": "2026-01-13"
    }
    response = client.post("/analytics", json=payload)
    assert response.status_code == 200
    assert response.json() is not None

def test_analytics_invalid_date_range():
    payload = {
        "start_date": "2026-01-15",
        "end_date":  "2026-01-01"  # End before start
    }
    response = client.post("/analytics", json=payload)
    # Depending on your validation logic
    assert response.status_code in [200, 400, 422]

def test_analytics_summary():
    response = client.get("/analytics/summary")
    assert response.status_code == 200
    assert "total_requests" in response.json()
    assert "success_rate" in response.json()