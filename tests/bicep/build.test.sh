#!/bin/bash
# T007: Bicep build validation test
set -e

echo "🔍 Testing Bicep build..."

if az bicep build --file infra/main.bicep --outfile /tmp/main.json 2>&1 | grep -q "error"; then
    echo "❌ Build failed: Cannot compile Bicep to ARM JSON"
    exit 1
fi

# Validate JSON structure
if ! jq -e '.resources | length > 0' /tmp/main.json > /dev/null 2>&1; then
    echo "❌ Build validation failed: No resources defined in compiled template"
    exit 1
fi

echo "✅ Build valid"
exit 0
