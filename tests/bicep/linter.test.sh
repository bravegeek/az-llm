#!/bin/bash
# T006: Bicep syntax validation test
set -e

echo "🔍 Testing Bicep syntax validation..."

if az bicep build --file infra/main.bicep --stdout > /dev/null 2>&1; then
    echo "✅ Syntax valid"
    exit 0
else
    echo "❌ Syntax error: Bicep file has syntax errors"
    exit 1
fi
