from fastapi import FastAPI, HTTPException
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel
from typing import Dict, Optional
import uuid
import time
import random
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="CryptoSpins API",
    description="A crypto-enabled gaming backend API for high-stakes spinning action",
    version="1.0.0"
)

# In-memory storage (in production, use Redis/Database)
user_balances: Dict[str, float] = {}
bet_history: Dict[str, Dict] = {}

# Pydantic models
class BetRequest(BaseModel):
    user_id: str
    amount: float
    game_type: str = "slots"
    multiplier: Optional[float] = 2.0

class BetResponse(BaseModel):
    bet_id: str
    user_id: str
    amount: float
    win_amount: float
    result: str
    timestamp: str

class BalanceResponse(BaseModel):
    user_id: str
    balance: float
    last_updated: str

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "Welcome to CryptoSpins API - Where Crypto Meets Gaming!", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    """Health check endpoint for monitoring"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "service": "cryptospins-api",
        "version": "1.0.0"
    }

@app.get("/balance/{user_id}", response_model=BalanceResponse)
async def get_balance(user_id: str):
    """Get user balance"""
    if user_id not in user_balances:
        # Initialize new user with starting balance
        user_balances[user_id] = 1000.0
        logger.info(f"New user {user_id} initialized with balance: 1000.0")
    
    return BalanceResponse(
        user_id=user_id,
        balance=user_balances[user_id],
        last_updated=datetime.utcnow().isoformat()
    )

@app.post("/bet", response_model=BetResponse)
async def place_bet(bet_request: BetRequest):
    """Place a bet"""
    user_id = bet_request.user_id
    amount = bet_request.amount
    
    # Validate amount
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Bet amount must be positive")
    
    # Initialize user balance if not exists
    if user_id not in user_balances:
        user_balances[user_id] = 1000.0
    
    # Check sufficient balance
    if user_balances[user_id] < amount:
        raise HTTPException(status_code=400, detail="Insufficient balance")
    
    # Deduct bet amount
    user_balances[user_id] -= amount
    
    # Simulate game result (30% win rate for high stakes!)
    bet_id = str(uuid.uuid4())
    win_probability = 0.3
    won = random.random() < win_probability
    
    if won:
        win_amount = amount * bet_request.multiplier
        user_balances[user_id] += win_amount
        result = "win"
        logger.info(f"User {user_id} won {win_amount} with bet {bet_id}")
    else:
        win_amount = 0
        result = "loss"
        logger.info(f"User {user_id} lost {amount} with bet {bet_id}")
    
    # Store bet history
    bet_history[bet_id] = {
        "user_id": user_id,
        "amount": amount,
        "win_amount": win_amount,
        "result": result,
        "game_type": bet_request.game_type,
        "timestamp": datetime.utcnow().isoformat()
    }
    
    return BetResponse(
        bet_id=bet_id,
        user_id=user_id,
        amount=amount,
        win_amount=win_amount,
        result=result,
        timestamp=datetime.utcnow().isoformat()
    )

@app.get("/bet/{bet_id}")
async def get_bet_details(bet_id: str):
    """Get bet details by ID"""
    if bet_id not in bet_history:
        raise HTTPException(status_code=404, detail="Bet not found")
    
    return bet_history[bet_id]

@app.get("/stats")
async def get_stats():
    """Get overall gaming statistics"""
    total_bets = len(bet_history)
    total_wins = sum(1 for bet in bet_history.values() if bet["result"] == "win")
    total_losses = total_bets - total_wins
    total_wagered = sum(bet["amount"] for bet in bet_history.values())
    total_winnings = sum(bet["win_amount"] for bet in bet_history.values())
    
    return {
        "total_bets": total_bets,
        "total_wins": total_wins,
        "total_losses": total_losses,
        "win_rate": total_wins / total_bets if total_bets > 0 else 0,
        "total_wagered": total_wagered,
        "total_winnings": total_winnings,
        "house_edge": (total_wagered - total_winnings) / total_wagered if total_wagered > 0 else 0,
        "active_users": len(user_balances)
    }

@app.get("/metrics", response_class=PlainTextResponse)
async def get_metrics():
    """Prometheus-style metrics endpoint"""
    stats = await get_stats()
    
    metrics = [
        f'cryptospins_total_bets {stats["total_bets"]}',
        f'cryptospins_total_wins {stats["total_wins"]}',
        f'cryptospins_total_losses {stats["total_losses"]}',
        f'cryptospins_win_rate {stats["win_rate"]}',
        f'cryptospins_total_wagered {stats["total_wagered"]}',
        f'cryptospins_total_winnings {stats["total_winnings"]}',
        f'cryptospins_house_edge {stats["house_edge"]}',
        f'cryptospins_active_users {stats["active_users"]}',
    ]
    
    return "\n".join(metrics)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)