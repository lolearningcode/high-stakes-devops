#!/bin/bash

# CryptoSpins API Test Runner
set -e

echo "🧪 Running CryptoSpins API Tests"
echo "================================"

# Check if we're in the right directory
if [ ! -f "pytest.ini" ]; then
    echo "❌ Error: pytest.ini not found. Please run this script from the api/ directory."
    exit 1
fi

# Install test dependencies
echo "📦 Installing test dependencies..."
pip install -r requirements-dev.txt

# Run tests with coverage
echo "🏃 Running tests..."
python3.10 -m pytest

# Check if coverage HTML report was generated
if [ -d "htmlcov" ]; then
    echo ""
    echo "✅ Tests completed!"
    echo "📊 Coverage report generated in htmlcov/index.html"
    echo "💡 Open htmlcov/index.html in your browser to view detailed coverage"
else
    echo "✅ Tests completed!"
fi

echo ""
echo "🎯 Test Summary:"
echo "- Unit tests: API endpoints, validation, error handling"
echo "- Business logic: Game mechanics, balance management, statistics"
echo "- Edge cases: Boundary conditions, concurrent users"
echo ""
echo "Next steps:"
echo "1. Review any failed tests above"
echo "2. Check coverage report for untested code paths" 
echo "3. Add more tests for any gaps identified"