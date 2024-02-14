import pytest
from app import app as flask_app  # Importieren Sie die Flask-Anwendung aus app.py

@pytest.fixture
def app():
    yield flask_app

@pytest.fixture
def client(app):
    return app.test_client()

def test_home_page(client):
    response = client.get("/")
    assert response.status_code == 200
    assert b"Produkt 1" in response.data
    assert b"Produkt 2" in response.data
    assert b"Produkt 3" in response.data
