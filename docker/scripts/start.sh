#!/bin/bash
# Start Docker Compose services for az-llm project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "🐳 Starting az-llm Docker services..."

# Check prerequisites
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found"
    echo "📝 Copy .env.example to .env and add your Azure credentials:"
    echo "   cp .env.example .env"
    echo "   nano .env"
    exit 1
fi

if [ ! -f docker/litellm/config.yaml ]; then
    echo "❌ Error: docker/litellm/config.yaml not found"
    exit 1
fi

# Validate compose file
echo "✓ Validating docker-compose.yml..."
docker compose config > /dev/null

# Pull latest images
echo "📥 Pulling latest images..."
docker compose pull

# Start services
echo "🚀 Starting services..."
docker compose up -d

# Wait for health checks
echo "⏳ Waiting for services to be healthy..."
sleep 5

# Show status
docker compose ps

echo ""
echo "✅ Services started successfully!"
echo ""
echo "📍 Access points:"
echo "   - OpenWebUI: http://localhost:3000"
echo "   - LiteLLM:   http://localhost:4000 (localhost only)"
echo ""
echo "📊 View logs:"
echo "   docker compose logs -f"
echo ""
echo "🛑 Stop services:"
echo "   docker compose down"
