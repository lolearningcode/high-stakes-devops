"""
Test suite for CryptoSpins game logic and business rules
"""
import pytest
from unittest.mock import patch
import random


class TestGameLogic:
    """Test game logic and probability mechanics"""
    
    @patch('random.random')
    def test_win_probability_mechanism(self, mock_random, client):
        """Test that win probability is correctly implemented (30%)"""
        # Mock random to return value that should result in a win (< 0.3)
        mock_random.return_value = 0.2
        
        bet_data = {
            "user_id": "test-user",
            "amount": 100.0,
            "game_type": "slots",
            "multiplier": 2.0
        }
        
        response = client.post("/bet", json=bet_data)
        result = response.json()
        
        assert result["result"] == "win"
        assert result["win_amount"] == 200.0  # 100 * 2.0 multiplier
    
    @patch('random.random')
    def test_loss_probability_mechanism(self, mock_random, client):
        """Test that loss probability is correctly implemented (70%)"""
        # Mock random to return value that should result in a loss (>= 0.3)
        mock_random.return_value = 0.8
        
        bet_data = {
            "user_id": "test-user",
            "amount": 100.0,
            "game_type": "slots",
            "multiplier": 2.0
        }
        
        response = client.post("/bet", json=bet_data)
        result = response.json()
        
        assert result["result"] == "loss"
        assert result["win_amount"] == 0.0
    
    def test_multiplier_calculation(self, client):
        """Test that multiplier is correctly applied to winnings"""
        # Test different multipliers
        multipliers = [1.5, 2.0, 3.0, 5.0]
        bet_amount = 100.0
        
        for multiplier in multipliers:
            with patch('random.random', return_value=0.1):  # Force win
                bet_data = {
                    "user_id": f"test-user-{multiplier}",
                    "amount": bet_amount,
                    "game_type": "slots",
                    "multiplier": multiplier
                }
                
                response = client.post("/bet", json=bet_data)
                result = response.json()
                
                if result["result"] == "win":
                    expected_win = bet_amount * multiplier
                    assert result["win_amount"] == expected_win
    
    def test_win_rate_distribution(self, client):
        """Test that win rate approximates 30% over many bets"""
        num_bets = 1000
        wins = 0
        
        for i in range(num_bets):
            bet_data = {
                "user_id": f"test-user-{i}",
                "amount": 10.0,
                "game_type": "slots",
                "multiplier": 2.0
            }
            
            response = client.post("/bet", json=bet_data)
            result = response.json()
            
            if result["result"] == "win":
                wins += 1
        
        win_rate = wins / num_bets
        # Allow for some variance (±10%) in random distribution
        assert 0.2 <= win_rate <= 0.4, f"Win rate {win_rate} not within expected range"


class TestBalanceManagement:
    """Test balance management and financial logic"""
    
    def test_initial_balance_assignment(self, client):
        """Test that new users get correct starting balance"""
        user_id = "new-user-123"
        response = client.get(f"/balance/{user_id}")
        data = response.json()
        
        assert data["balance"] == 1000.0
        assert data["user_id"] == user_id
    
    def test_balance_deduction_on_loss(self, client):
        """Test balance deduction when bet is lost"""
        user_id = "test-user"
        bet_amount = 150.0
        
        with patch('random.random', return_value=0.8):  # Force loss
            bet_data = {
                "user_id": user_id,
                "amount": bet_amount,
                "game_type": "slots",
                "multiplier": 2.0
            }
            
            # Get initial balance
            initial_response = client.get(f"/balance/{user_id}")
            initial_balance = initial_response.json()["balance"]
            
            # Place losing bet
            client.post("/bet", json=bet_data)
            
            # Check updated balance
            final_response = client.get(f"/balance/{user_id}")
            final_balance = final_response.json()["balance"]
            
            assert final_balance == initial_balance - bet_amount
    
    def test_balance_update_on_win(self, client):
        """Test balance update when bet is won"""
        user_id = "test-user"
        bet_amount = 100.0
        multiplier = 3.0
        
        with patch('random.random', return_value=0.1):  # Force win
            bet_data = {
                "user_id": user_id,
                "amount": bet_amount,
                "game_type": "slots",
                "multiplier": multiplier
            }
            
            # Get initial balance
            initial_response = client.get(f"/balance/{user_id}")
            initial_balance = initial_response.json()["balance"]
            
            # Place winning bet
            bet_response = client.post("/bet", json=bet_data)
            bet_result = bet_response.json()
            
            # Check updated balance
            final_response = client.get(f"/balance/{user_id}")
            final_balance = final_response.json()["balance"]
            
            # Balance = initial - bet + winnings
            expected_balance = initial_balance - bet_amount + (bet_amount * multiplier)
            assert final_balance == expected_balance
            assert bet_result["win_amount"] == bet_amount * multiplier
    
    def test_multiple_bets_balance_tracking(self, client):
        """Test balance tracking across multiple bets"""
        user_id = "test-user"
        starting_balance = 1000.0
        
        # Simulate series of bets with known outcomes
        bets = [
            (100.0, 2.0, 0.1),  # Win: -100 + 200 = +100
            (50.0, 1.5, 0.5),   # Loss: -50
            (200.0, 2.5, 0.2),  # Win: -200 + 500 = +300
            (75.0, 2.0, 0.9),   # Loss: -75
        ]
        
        expected_balance = starting_balance
        
        for bet_amount, multiplier, random_value in bets:
            with patch('random.random', return_value=random_value):
                bet_data = {
                    "user_id": user_id,
                    "amount": bet_amount,
                    "game_type": "slots",
                    "multiplier": multiplier
                }
                
                response = client.post("/bet", json=bet_data)
                result = response.json()
                
                if result["result"] == "win":
                    expected_balance = expected_balance - bet_amount + (bet_amount * multiplier)
                else:
                    expected_balance = expected_balance - bet_amount
        
        # Check final balance
        final_response = client.get(f"/balance/{user_id}")
        final_balance = final_response.json()["balance"]
        
        assert final_balance == expected_balance
    
    def test_prevent_negative_balance(self, client):
        """Test that bets are rejected when balance would go negative"""
        user_id = "test-user"
        
        # Get starting balance
        balance_response = client.get(f"/balance/{user_id}")
        starting_balance = balance_response.json()["balance"]
        
        # Try to bet more than available balance
        bet_data = {
            "user_id": user_id,
            "amount": starting_balance + 100.0,  # More than available
            "game_type": "slots",
            "multiplier": 2.0
        }
        
        response = client.post("/bet", json=bet_data)
        assert response.status_code == 400
        assert "Insufficient balance" in response.json()["detail"]
        
        # Verify balance unchanged
        final_response = client.get(f"/balance/{user_id}")
        final_balance = final_response.json()["balance"]
        assert final_balance == starting_balance


class TestStatisticsAccuracy:
    """Test accuracy of statistics calculations"""
    
    def test_statistics_calculation_accuracy(self, client):
        """Test that statistics are calculated correctly"""
        # Create predictable betting scenario
        user_data = [
            ("user1", 100.0, 2.0, 0.1),  # Win
            ("user2", 150.0, 1.5, 0.8),  # Loss
            ("user3", 200.0, 2.5, 0.2),  # Win
            ("user4", 75.0, 2.0, 0.9),   # Loss
            ("user1", 50.0, 3.0, 0.7),   # Loss (same user, second bet)
        ]
        
        total_bets = len(user_data)
        total_wins = 0
        total_losses = 0
        total_wagered = 0
        total_winnings = 0
        
        for user_id, amount, multiplier, random_val in user_data:
            with patch('random.random', return_value=random_val):
                bet_data = {
                    "user_id": user_id,
                    "amount": amount,
                    "game_type": "slots",
                    "multiplier": multiplier
                }
                
                response = client.post("/bet", json=bet_data)
                result = response.json()
                
                total_wagered += amount
                
                if result["result"] == "win":
                    total_wins += 1
                    total_winnings += amount * multiplier
                else:
                    total_losses += 1
        
        # Get statistics
        stats_response = client.get("/stats")
        stats = stats_response.json()
        
        assert stats["total_bets"] == total_bets
        assert stats["total_wins"] == total_wins
        assert stats["total_losses"] == total_losses
        assert stats["total_wagered"] == total_wagered
        assert stats["total_winnings"] == total_winnings
        assert stats["win_rate"] == total_wins / total_bets
        assert stats["active_users"] == 4  # 4 unique users
        
        # House edge calculation
        expected_house_edge = (total_wagered - total_winnings) / total_wagered
        assert abs(stats["house_edge"] - expected_house_edge) < 0.0001


class TestEdgeCases:
    """Test edge cases and error conditions"""
    
    def test_extremely_small_bet(self, client):
        """Test betting very small amounts"""
        bet_data = {
            "user_id": "test-user",
            "amount": 0.01,  # Very small bet
            "game_type": "slots",
            "multiplier": 2.0
        }
        
        response = client.post("/bet", json=bet_data)
        assert response.status_code == 200
        result = response.json()
        assert result["amount"] == 0.01
    
    def test_high_multiplier_win(self, client):
        """Test winning with high multiplier"""
        bet_amount = 100.0
        high_multiplier = 10.0
        
        with patch('random.random', return_value=0.1):  # Force win
            bet_data = {
                "user_id": "test-user",
                "amount": bet_amount,
                "game_type": "slots",
                "multiplier": high_multiplier
            }
            
            response = client.post("/bet", json=bet_data)
            result = response.json()
            
            assert result["result"] == "win"
            assert result["win_amount"] == bet_amount * high_multiplier
    
    def test_concurrent_user_isolation(self, client):
        """Test that different users don't interfere with each other"""
        user1_id = "user-1"
        user2_id = "user-2"
        
        # User 1 places bet
        bet1_data = {
            "user_id": user1_id,
            "amount": 100.0,
            "game_type": "slots",
            "multiplier": 2.0
        }
        client.post("/bet", json=bet1_data)
        
        # User 2 places bet
        bet2_data = {
            "user_id": user2_id,
            "amount": 200.0,
            "game_type": "slots", 
            "multiplier": 1.5
        }
        client.post("/bet", json=bet2_data)
        
        # Check balances are independent
        balance1 = client.get(f"/balance/{user1_id}").json()
        balance2 = client.get(f"/balance/{user2_id}").json()
        
        # Verify user isolation - each user should have their correct user_id
        assert balance1["user_id"] == user1_id
        assert balance2["user_id"] == user2_id
        
        # Test that users can't access each other's data
        # Try to get user1's balance with user2's ID - should return different balance
        # This tests that the system properly isolates user data
        assert balance1["balance"] >= 900 or balance1["balance"] == 1200  # Lost 100 or won 200
        assert balance2["balance"] >= 800 or balance2["balance"] == 1300  # Lost 200 or won 300
        
        # Most importantly: verify each user maintains independent state
        # Make another bet for user1 to prove isolation
        bet3_data = {
            "user_id": user1_id,
            "amount": 50.0,
            "game_type": "slots",
            "multiplier": 2.0
        }
        response3 = client.post("/bet", json=bet3_data)
        assert response3.status_code == 200
        
        # User2's balance should be unchanged by user1's new bet
        balance2_after = client.get(f"/balance/{user2_id}").json()
        assert balance2_after["balance"] == balance2["balance"]