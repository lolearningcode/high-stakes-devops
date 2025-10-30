#!/bin/bash

# CryptoSpins API Load Test Script
# This script generates realistic API traffic to test monitoring

set -e

API_URL="http://$(kubectl get service cryptospins-api -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "🎮 Starting CryptoSpins API load test..."
echo "📡 API URL: $API_URL"

# Function to make a bet
make_bet() {
    local user_id="user-$((RANDOM % 50))"
    local amount=$(echo "scale=2; $RANDOM/32767*100" | bc)
    local multiplier=$(echo "scale=1; 1.5 + ($RANDOM/32767)*2.5" | bc)
    
    curl -s -X POST "$API_URL/bet" \
        -H "Content-Type: application/json" \
        -d '{
            "user_id": "'$user_id'",
            "amount": '$amount',
            "game_type": "slots",
            "multiplier": '$multiplier'
        }' > /dev/null
    
    echo "💰 Bet placed: User $user_id, Amount: \$$amount, Multiplier: ${multiplier}x"
}

# Function to check balance
check_balance() {
    local user_id="user-$((RANDOM % 50))"
    curl -s "$API_URL/balance/$user_id" > /dev/null
    echo "💳 Balance checked for $user_id"
}

# Function to get stats
check_stats() {
    curl -s "$API_URL/stats" > /dev/null
    echo "📊 Stats retrieved"
}

# Function to health check
health_check() {
    curl -s "$API_URL/health" > /dev/null
    echo "🏥 Health checked"
}

echo "🚀 Generating realistic gambling traffic..."
echo "⏰ Running for 5 minutes with varying load patterns..."

# Generate traffic for 5 minutes with different patterns
for minute in {1..5}; do
    echo "📈 Minute $minute - Simulating $(($minute * 10)) concurrent users"
    
    # Burst of activity
    for i in $(seq 1 $(($minute * 10))); do
        # 70% bets, 20% balance checks, 8% stats, 2% health
        rand=$((RANDOM % 100))
        if [ $rand -lt 70 ]; then
            make_bet &
        elif [ $rand -lt 90 ]; then
            check_balance &
        elif [ $rand -lt 98 ]; then
            check_stats &
        else
            health_check &
        fi
        
        # Slight delay to prevent overwhelming
        sleep 0.1
    done
    
    # Wait for requests to complete
    wait
    
    # Pause between minutes
    echo "😴 Brief pause..."
    sleep 10
done

echo "🎯 Load test completed!"
echo "📊 Check your Grafana dashboard for metrics"
echo "🔔 Monitor Prometheus alerts for any triggers"

# Final health check
echo "🏥 Final API health check:"
curl -s "$API_URL/health" | jq .