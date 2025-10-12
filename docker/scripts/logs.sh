#!/bin/bash
# View logs for Docker Compose services

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

SERVICE="${1:-}"

if [ -z "$SERVICE" ]; then
    echo "📋 Following logs for all services (Ctrl+C to exit)..."
    docker compose logs -f
else
    echo "📋 Following logs for $SERVICE (Ctrl+C to exit)..."
    docker compose logs -f "$SERVICE"
fi
