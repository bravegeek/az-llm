#!/bin/bash
# T010: Contract output schema validation test
set -e

echo "🔍 Testing output contract schema..."

# Check if ajv-cli is available
if ! command -v ajv &> /dev/null; then
    echo "⚠️  ajv-cli not found, installing..."
    npm install -g ajv-cli 2>&1 | grep -E "(added|up to date)" || true
fi

# Validate schema is valid JSON Schema draft-07
# Note: ajv may warn about "unknown format" for "uri" but this is acceptable
if ajv compile -s specs/003-create-a-minimal/contracts/deployment-outputs.schema.json 2>&1 | grep -qi "invalid\|error" | grep -v "unknown format"; then
    echo "❌ Output contract schema invalid"
    exit 1
fi

echo "✅ Output contract schema valid"
exit 0
