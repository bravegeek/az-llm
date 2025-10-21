#!/bin/bash
# T004: Contract input schema validation test
set -e

echo "=== Testing input contract schema ==="

# Check if ajv-cli is available
if ! command -v ajv &> /dev/null; then
    echo "⚠️  ajv-cli not found, installing..."
    npm install -g ajv-cli 2>&1 | grep -E "(added|up to date)" || true
fi

# Extract values from ARM parameters file for validation
jq '.parameters | map_values(.value)' infra/main.parameters.json > /tmp/params-values.json

# Validate extracted values against schema
if ajv validate -s specs/004-migrate-from-azure/contracts/input-schema.json \
   -d /tmp/params-values.json 2>&1 | grep -q "invalid"; then
    echo "❌ Input parameters validation failed"
    exit 1
fi

echo "✅ Input parameters valid"
exit 0
