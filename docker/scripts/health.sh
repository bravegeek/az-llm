#!/bin/bash
# Check health status of Docker Compose services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "🏥 Checking service health..."
echo ""

# Show container status
docker compose ps

echo ""
echo "🔍 Health check details:"
echo ""

# Check LiteLLM
echo "LiteLLM:"
if curl -f -s http://localhost:4000/health > /dev/null 2>&1; then
    echo "  ✅ Health endpoint responding"
else
    echo "  ❌ Health endpoint not responding"
fi

echo ""

# Check OpenWebUI
echo "OpenWebUI:"
if curl -f -s http://localhost:3000 > /dev/null 2>&1; then
    echo "  ✅ Web interface responding"
else
    echo "  ❌ Web interface not responding"
fi

echo ""
echo "💡 Tip: Use 'docker compose logs <service>' to debug issues"
