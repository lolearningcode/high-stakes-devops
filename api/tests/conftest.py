# Pytest configuration
import pytest
from fastapi.testclient import TestClient
import sys
import os

# Add the app directory to the path so we can import main
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'app'))

from main import app

@pytest.fixture
def client():
    """Create a test client for the FastAPI app"""
    return TestClient(app)

@pytest.fixture
def sample_user_id():
    """Sample user ID for testing"""
    return "test-user-123"

@pytest.fixture
def sample_bet_data():
    """Sample bet data for testing"""
    return {
        "user_id": "test-user-123",
        "amount": 100.0,
        "game_type": "slots",
        "multiplier": 2.0
    }

@pytest.fixture(autouse=True)
def reset_app_state():
    """Reset application state before each test"""
    # Clear in-memory storage before each test
    from main import user_balances, bet_history
    user_balances.clear()
    bet_history.clear()
    yield
    # Clean up after test
    user_balances.clear()
    bet_history.clear()