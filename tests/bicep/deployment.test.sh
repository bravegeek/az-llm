#!/bin/bash
# T011: Integration deployment test (dry-run with what-if)
set -e

RESOURCE_GROUP=${1:-"test-rg"}

echo "🔍 Testing deployment dry-run for resource group: $RESOURCE_GROUP"

# Note: This test requires a valid Azure resource group to exist
# It will fail if Bicep has no resources or if parameters are invalid

if az deployment group what-if \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json \
  2>&1 | grep -q "Error"; then
    echo "❌ Deployment validation failed"
    exit 1
fi

echo "✅ Deployment validation passed"
exit 0
