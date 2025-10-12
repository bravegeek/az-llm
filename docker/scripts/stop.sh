#!/bin/bash
# Stop Docker Compose services for az-llm project

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

echo "🛑 Stopping az-llm Docker services..."

docker compose down

echo "✅ Services stopped successfully"
