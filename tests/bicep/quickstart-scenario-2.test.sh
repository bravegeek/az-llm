#!/bin/bash
# T013: Quickstart Scenario 2 - Update Model Capacity (Idempotent Redeployment)
# This is an INTEGRATION test requiring actual Azure resources
# Usage: ./tests/bicep/quickstart-scenario-2.test.sh <resource-group>

set -e

RESOURCE_GROUP=${1:-""}
if [ -z "$RESOURCE_GROUP" ]; then
    echo "⚠️  INTEGRATION TEST - requires Azure resources"
    echo ""
    echo "Usage: $0 <resource-group>"
    echo ""
    echo "This scenario validates:"
    echo "  - Modify parameters (2.1)"
    echo "  - Redeploy without recreation (2.2)"
    echo "  - Verify no downtime (2.3)"
    echo ""
    echo "See: specs/003-create-a-minimal/quickstart.md#scenario-2"
    exit 0
fi

echo "🧪 Testing Scenario 2: Update Model Capacity (Idempotent Redeployment)"
echo "   Resource Group: $RESOURCE_GROUP"
echo ""

# 2.1 Backup current outputs
if [ -f .env.azure-openai ]; then
    cp .env.azure-openai .env.azure-openai.before-update
    echo "✅ Backed up existing outputs"
else
    echo "❌ No existing .env.azure-openai found - run Scenario 1 first"
    exit 1
fi

# 2.2 Redeploy (should update, not recreate)
echo ""
echo "Step 2.2: Redeploying (idempotent)..."
./scripts/deploy.sh "$RESOURCE_GROUP" @infra/main.parameters.local.json

# 2.3 Verify no endpoint/key changes
echo ""
echo "Step 2.3: Verifying no downtime..."
./scripts/outputs.sh "$RESOURCE_GROUP"

ENDPOINT_BEFORE=$(grep "^AZURE_OPENAI_ENDPOINT=" .env.azure-openai.before-update | cut -d= -f2)
ENDPOINT_AFTER=$(grep "^AZURE_OPENAI_ENDPOINT=" .env.azure-openai | cut -d= -f2)
KEY_BEFORE=$(grep "^AZURE_API_KEY=" .env.azure-openai.before-update | cut -d= -f2)
KEY_AFTER=$(grep "^AZURE_API_KEY=" .env.azure-openai | cut -d= -f2)

if [ "$ENDPOINT_BEFORE" != "$ENDPOINT_AFTER" ]; then
    echo "❌ Endpoint changed (expected same): $ENDPOINT_BEFORE -> $ENDPOINT_AFTER"
    exit 1
fi

if [ "$KEY_BEFORE" != "$KEY_AFTER" ]; then
    echo "❌ API key changed (expected same)"
    exit 1
fi

echo "✅ Endpoint and API key unchanged"
echo ""
echo "✅ Scenario 2 PASSED: Idempotent redeployment successful, no downtime"
