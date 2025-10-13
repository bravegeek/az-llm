#!/bin/bash
# T012: Quickstart Scenario 1 - Fresh Deployment (No Existing OpenAI Resources)
# This is an INTEGRATION test requiring actual Azure resources
# Usage: ./tests/bicep/quickstart-scenario-1.test.sh <resource-group>

set -e

RESOURCE_GROUP=${1:-""}
if [ -z "$RESOURCE_GROUP" ]; then
    echo "⚠️  INTEGRATION TEST - requires Azure resources"
    echo ""
    echo "Usage: $0 <resource-group>"
    echo ""
    echo "This scenario validates:"
    echo "  - Prepare parameters (1.1)"
    echo "  - Validate Bicep syntax (1.2)"
    echo "  - Dry-run deployment (1.3)"
    echo "  - Execute deployment (1.4)"
    echo "  - Verify outputs (1.5)"
    echo "  - Update Docker configuration (1.6)"
    echo "  - Test Docker connectivity (1.7)"
    echo ""
    echo "See: specs/003-create-a-minimal/quickstart.md#scenario-1"
    exit 0  # Exit 0 when called without args (not a failure)
fi

echo "🧪 Testing Scenario 1: Fresh Deployment (No Existing OpenAI Resources)"
echo "   Resource Group: $RESOURCE_GROUP"
echo ""

# 1.1 Prepare parameters (assume already done by user)
if [ ! -f infra/main.parameters.local.json ]; then
    echo "❌ infra/main.parameters.local.json not found"
    echo "   Run: cp infra/main.parameters.json infra/main.parameters.local.json"
    exit 1
fi

# 1.2 Validate Bicep syntax
echo "Step 1.2: Validating Bicep syntax..."
./tests/bicep/linter.test.sh
./tests/bicep/build.test.sh

# 1.3 Dry-run deployment (what-if)
echo ""
echo "Step 1.3: Dry-run deployment (what-if)..."
az deployment group what-if \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.local.json \
  --no-pretty-print > /dev/null

# 1.4 Execute deployment
echo ""
echo "Step 1.4: Executing deployment..."
./scripts/deploy.sh "$RESOURCE_GROUP" @infra/main.parameters.local.json

# 1.5 Verify outputs
echo ""
echo "Step 1.5: Verifying outputs..."
./scripts/outputs.sh "$RESOURCE_GROUP"

if [ ! -f .env.azure-openai ]; then
    echo "❌ .env.azure-openai not created"
    exit 1
fi

# Verify all 7 required variables exist
REQUIRED_VARS=("AZURE_OPENAI_ENDPOINT" "AZURE_API_KEY" "GPT41_DEPLOYMENT_NAME" "GPT41_MINI_DEPLOYMENT_NAME" "GPT4O_DEPLOYMENT_NAME" "FLUX_DEPLOYMENT_NAME" "DEEPSEEK_DEPLOYMENT_NAME")
for var in "${REQUIRED_VARS[@]}"; do
    if ! grep -q "^${var}=" .env.azure-openai; then
        echo "❌ Missing variable: $var"
        exit 1
    fi
done

echo "✅ All 7 environment variables present"

# 1.6 + 1.7 Docker tests (manual for now)
echo ""
echo "Step 1.6-1.7: Docker connectivity (manual)"
echo "   Run: source .env.azure-openai && docker compose up -d litellm"
echo "   Test: curl -X POST http://localhost:4000/chat/completions ..."

echo ""
echo "✅ Scenario 1 PASSED: Fresh deployment successful, outputs valid"
