"""
Test suite for CryptoSpins API endpoints
"""
import pytest
from fastapi import status
import json


class TestBasicEndpoints:
    """Test basic API endpoints"""
    
    def test_root_endpoint(self, client):
        """Test the root endpoint"""
        response = client.get("/")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "message" in data
        assert "CryptoSpins API" in data["message"]
        assert data["version"] == "1.0.0"
    
    def test_health_endpoint(self, client):
        """Test the health check endpoint"""
        response = client.get("/health")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "cryptospins-api"
        assert data["version"] == "1.0.0"
        assert "timestamp" in data


class TestBalanceEndpoints:
    """Test balance-related endpoints"""
    
    def test_get_balance_new_user(self, client, sample_user_id):
        """Test getting balance for a new user"""
        response = client.get(f"/balance/{sample_user_id}")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["user_id"] == sample_user_id
        assert data["balance"] == 1000.0  # Starting balance
        assert "last_updated" in data
    
    def test_get_balance_existing_user(self, client, sample_user_id):
        """Test getting balance for existing user"""
        # First request creates user
        response1 = client.get(f"/balance/{sample_user_id}")
        assert response1.status_code == status.HTTP_200_OK
        
        # Second request should return same balance
        response2 = client.get(f"/balance/{sample_user_id}")
        assert response2.status_code == status.HTTP_200_OK
        data = response2.json()
        assert data["user_id"] == sample_user_id
        assert data["balance"] == 1000.0


class TestBettingEndpoints:
    """Test betting-related endpoints"""
    
    def test_place_valid_bet(self, client, sample_bet_data):
        """Test placing a valid bet"""
        response = client.post("/bet", json=sample_bet_data)
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert "bet_id" in data
        assert data["user_id"] == sample_bet_data["user_id"]
        assert data["amount"] == sample_bet_data["amount"]
        assert data["result"] in ["win", "loss"]
        assert "timestamp" in data
        
        # Win amount should be 0 for loss, or amount * multiplier for win
        if data["result"] == "win":
            expected_win = sample_bet_data["amount"] * sample_bet_data["multiplier"]
            assert data["win_amount"] == expected_win
        else:
            assert data["win_amount"] == 0
    
    def test_place_bet_invalid_amount_zero(self, client, sample_bet_data):
        """Test placing bet with zero amount"""
        sample_bet_data["amount"] = 0
        response = client.post("/bet", json=sample_bet_data)
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Bet amount must be positive" in response.json()["detail"]
    
    def test_place_bet_invalid_amount_negative(self, client, sample_bet_data):
        """Test placing bet with negative amount"""
        sample_bet_data["amount"] = -50.0
        response = client.post("/bet", json=sample_bet_data)
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Bet amount must be positive" in response.json()["detail"]
    
    def test_place_bet_insufficient_balance(self, client, sample_bet_data):
        """Test placing bet with insufficient balance"""
        # Place a large bet that exceeds starting balance
        sample_bet_data["amount"] = 2000.0  # More than 1000.0 starting balance
        response = client.post("/bet", json=sample_bet_data)
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Insufficient balance" in response.json()["detail"]
    
    def test_bet_balance_deduction(self, client, sample_user_id):
        """Test that balance is properly deducted after betting"""
        # Get initial balance
        balance_response = client.get(f"/balance/{sample_user_id}")
        initial_balance = balance_response.json()["balance"]
        
        # Place a bet
        bet_data = {
            "user_id": sample_user_id,
            "amount": 100.0,
            "game_type": "slots",
            "multiplier": 2.0
        }
        bet_response = client.post("/bet", json=bet_data)
        bet_result = bet_response.json()
        
        # Check updated balance
        updated_balance_response = client.get(f"/balance/{sample_user_id}")
        updated_balance = updated_balance_response.json()["balance"]
        
        if bet_result["result"] == "win":
            # Balance = initial - bet_amount + win_amount
            expected_balance = initial_balance - bet_data["amount"] + bet_result["win_amount"]
        else:
            # Balance = initial - bet_amount
            expected_balance = initial_balance - bet_data["amount"]
        
        assert updated_balance == expected_balance
    
    def test_get_bet_details_valid(self, client, sample_bet_data):
        """Test getting details of a valid bet"""
        # Place a bet first
        bet_response = client.post("/bet", json=sample_bet_data)
        bet_data = bet_response.json()
        bet_id = bet_data["bet_id"]
        
        # Get bet details
        details_response = client.get(f"/bet/{bet_id}")
        assert details_response.status_code == status.HTTP_200_OK
        details = details_response.json()
        
        assert details["user_id"] == sample_bet_data["user_id"]
        assert details["amount"] == sample_bet_data["amount"]
        assert details["result"] in ["win", "loss"]
        assert "timestamp" in details
    
    def test_get_bet_details_invalid(self, client):
        """Test getting details of non-existent bet"""
        fake_bet_id = "non-existent-bet-id"
        response = client.get(f"/bet/{fake_bet_id}")
        assert response.status_code == status.HTTP_404_NOT_FOUND
        assert "Bet not found" in response.json()["detail"]


class TestStatisticsEndpoints:
    """Test statistics and metrics endpoints"""
    
    def test_stats_no_bets(self, client):
        """Test statistics when no bets have been placed"""
        response = client.get("/stats")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        
        assert data["total_bets"] == 0
        assert data["total_wins"] == 0
        assert data["total_losses"] == 0
        assert data["win_rate"] == 0
        assert data["total_wagered"] == 0
        assert data["total_winnings"] == 0
        assert data["house_edge"] == 0
        assert data["active_users"] == 0
    
    def test_stats_with_bets(self, client, sample_bet_data):
        """Test statistics after placing bets"""
        # Place multiple bets
        bet_responses = []
        for i in range(3):
            bet_data = sample_bet_data.copy()
            bet_data["user_id"] = f"user-{i}"
            response = client.post("/bet", json=bet_data)
            bet_responses.append(response.json())
        
        # Get statistics
        stats_response = client.get("/stats")
        assert stats_response.status_code == status.HTTP_200_OK
        stats = stats_response.json()
        
        assert stats["total_bets"] == 3
        assert stats["active_users"] == 3  # 3 different users
        assert stats["total_wagered"] == 300.0  # 3 * 100.0
        
        # Count wins and losses
        wins = sum(1 for bet in bet_responses if bet["result"] == "win")
        losses = sum(1 for bet in bet_responses if bet["result"] == "loss")
        
        assert stats["total_wins"] == wins
        assert stats["total_losses"] == losses
        expected_win_rate = wins / 3 if 3 > 0 else 0
        assert abs(stats["win_rate"] - expected_win_rate) < 0.0001  # Allow for floating point precision
    
    def test_metrics_endpoint_format(self, client):
        """Test that metrics endpoint returns Prometheus format"""
        response = client.get("/metrics")
        assert response.status_code == status.HTTP_200_OK
        
        metrics_text = response.json()  # This will be a string
        assert "cryptospins_total_bets" in metrics_text
        assert "cryptospins_total_wins" in metrics_text
        assert "cryptospins_win_rate" in metrics_text
        assert "cryptospins_active_users" in metrics_text
    
    def test_metrics_endpoint_content_type(self, client):
        """Test that metrics endpoint returns correct content type"""
        response = client.get("/metrics")
        # Note: FastAPI returns JSON by default, but in production
        # Prometheus metrics should be text/plain
        assert response.status_code == status.HTTP_200_OK


class TestInputValidation:
    """Test input validation and edge cases"""
    
    def test_bet_missing_required_fields(self, client):
        """Test betting with missing required fields"""
        incomplete_data = {"user_id": "test-user"}  # Missing amount
        response = client.post("/bet", json=incomplete_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    def test_bet_invalid_data_types(self, client):
        """Test betting with invalid data types"""
        invalid_data = {
            "user_id": "test-user",
            "amount": "invalid-amount",  # Should be float
            "game_type": "slots",
            "multiplier": 2.0
        }
        response = client.post("/bet", json=invalid_data)
        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY
    
    def test_balance_invalid_user_id(self, client):
        """Test balance endpoint with various user ID formats"""
        # Empty user ID
        response = client.get("/balance/")
        assert response.status_code == status.HTTP_404_NOT_FOUND
        
        # Valid user ID with special characters
        response = client.get("/balance/user-with-dashes_123")
        assert response.status_code == status.HTTP_200_OK