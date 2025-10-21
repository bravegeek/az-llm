#!/bin/bash
# T005: Contract output schema validation test
set -e

echo "=== Testing output contract schema ==="

# Check if ajv-cli is available
if ! command -v ajv &> /dev/null; then
    echo "⚠️  ajv-cli not found, installing..."
    npm install -g ajv-cli 2>&1 | grep -E "(added|up to date)" || true
fi

# Build Bicep to get outputs structure
if ! az bicep build --file infra/main.bicep --outfile /tmp/main.json 2>/dev/null; then
    echo "⚠️  Cannot build Bicep (expected - no implementation yet)"
    exit 1
fi

# Extract outputs schema
jq '.outputs' /tmp/main.json > /tmp/outputs-structure.json

# Validate against output schema
if ajv validate -s specs/004-migrate-from-azure/contracts/output-schema.json \
   -d /tmp/outputs-structure.json 2>&1 | grep -q "invalid"; then
    echo "❌ Output schema validation failed"
    exit 1
fi

echo "✅ Output schema valid"
exit 0
