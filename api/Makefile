# CryptoSpins API Development Makefile

.PHONY: help install test test-watch lint format clean build run docker-build docker-run docker-test

# Default target
help:
	@echo "CryptoSpins API Development Commands"
	@echo "==================================="
	@echo "make install     - Install dependencies"
	@echo "make test        - Run all tests"
	@echo "make test-watch  - Run tests in watch mode"
	@echo "make lint        - Run linting"
	@echo "make format      - Format code"
	@echo "make run         - Run API locally"
	@echo "make build       - Build for production"
	@echo "make docker-build- Build Docker image"
	@echo "make docker-run  - Run in Docker"
	@echo "make docker-test - Run tests in Docker"
	@echo "make clean       - Clean temporary files"

# Install dependencies
install:
	pip install --upgrade pip
	pip install -r requirements-dev.txt

# Run tests
test:
	python -m pytest

# Run tests in watch mode
test-watch:
	python -m pytest --watch

# Run linting
lint:
	flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 . --count --exit-zero --max-complexity=10 --max-line-length=88 --statistics

# Format code (if you want to add black later)
format:
	@echo "Code formatting not configured yet. Consider adding black or autopep8."

# Run API locally
run:
	uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# Build production requirements
build:
	@echo "Building production requirements..."
	@echo "Production build complete"

# Docker commands
docker-build:
	docker build --platform linux/amd64 -t cryptospins-api .

docker-run:
	docker run -p 8000:8000 cryptospins-api

docker-test:
	docker build --target development --platform linux/amd64 -t cryptospins-api:test .
	docker run --rm cryptospins-api:test python -m pytest

# Clean temporary files
clean:
	rm -rf __pycache__/
	rm -rf .pytest_cache/
	rm -rf htmlcov/
	rm -rf .coverage
	rm -rf coverage.xml
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete