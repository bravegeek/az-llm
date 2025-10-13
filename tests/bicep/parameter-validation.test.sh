#!/bin/bash
# T008: Parameter validation test
set -e

echo "🔍 Testing parameter validation..."

# Check if ajv-cli is available
if ! command -v ajv &> /dev/null; then
    echo "⚠️  ajv-cli not found, installing..."
    npm install -g ajv-cli 2>&1 | grep -E "(added|up to date)" || true
fi

# Extract values from ARM parameters file for validation
jq '.parameters | map_values(.value)' infra/main.parameters.json > /tmp/params-values.json

# Validate extracted values against schema
if ajv validate -s specs/003-create-a-minimal/contracts/bicep-parameters.schema.json \
   -d /tmp/params-values.json 2>&1 | grep -q "invalid"; then
    echo "❌ Parameter validation failed: Parameters do not match schema"
    exit 1
fi

echo "✅ Parameters valid"
exit 0
