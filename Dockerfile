version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: career_coach_db
    environment:
      POSTGRES_DB: career_coach
      POSTGRES_USER: career_user
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-change_this_password}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U career_user -d career_coach"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend_network
    restart: unless-stopped

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: career_coach_redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    networks:
      - backend_network
    restart: unless-stopped

  # Backend API
  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: career_coach_api
    environment:
      - DATABASE_URL=postgresql://career_user:${POSTGRES_PASSWORD:-change_this_password}@postgres:5432/career_coach
      - REDIS_URL=redis://redis:6379/0
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - JWT_SECRET_KEY=${JWT_SECRET_KEY:-change-this-in-production}
      - FRONTEND_URL=${FRONTEND_URL:-http://localhost:3000}
      - ENVIRONMENT=${ENVIRONMENT:-development}
      - DEBUG=${DEBUG:-False}
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    volumes:
      - ./uploads:/app/uploads
    networks:
      - backend_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local

networks:
  backend_network:
    driver: bridge
