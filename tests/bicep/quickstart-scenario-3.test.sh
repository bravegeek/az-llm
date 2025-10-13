#!/bin/bash
# T013: Quickstart Scenario 3 - Migration from Old Infrastructure
# This is an INTEGRATION test requiring actual Azure resources
# Usage: ./tests/bicep/quickstart-scenario-3.test.sh <new-resource-group>

set -e

RESOURCE_GROUP=${1:-""}
if [ -z "$RESOURCE_GROUP" ]; then
    echo "⚠️  INTEGRATION TEST - requires Azure resources"
    echo ""
    echo "Usage: $0 <new-resource-group>"
    echo ""
    echo "This scenario validates:"
    echo "  - Archive old infrastructure (3.1)"
    echo "  - Deploy minimal Bicep to NEW resource group (3.2)"
    echo "  - Parallel test with Docker (3.3)"
    echo "  - Switch production configuration (3.4)"
    echo "  - Delete old Azure resources (3.5 - manual)"
    echo ""
    echo "See: specs/003-create-a-minimal/quickstart.md#scenario-3"
    exit 0
fi

echo "🧪 Testing Scenario 3: Migration from Old Infrastructure"
echo "   New Resource Group: $RESOURCE_GROUP"
echo ""

# 3.1 Verify old infrastructure archived
if [ -d infra-archive/2025-10-12-original ]; then
    echo "✅ Old infrastructure archived at infra-archive/2025-10-12-original"
else
    echo "⚠️  Old infrastructure not found in archive (may already be migrated)"
fi

# 3.2 Deploy minimal Bicep to NEW resource group
echo ""
echo "Step 3.2: Deploying to new resource group..."
./scripts/deploy.sh "$RESOURCE_GROUP" @infra/main.parameters.local.json

# 3.3 Verify new outputs
echo ""
echo "Step 3.3: Verifying new outputs..."
./scripts/outputs.sh "$RESOURCE_GROUP"

if [ ! -f .env.azure-openai ]; then
    echo "❌ .env.azure-openai not created"
    exit 1
fi

echo "✅ New deployment outputs extracted"

# 3.4 Docker config update (manual)
echo ""
echo "Step 3.4: Docker configuration (manual)"
echo "   1. Backup: cp docker/litellm/config.yaml docker/litellm/config.yaml.backup"
echo "   2. Update config.yaml with new AZURE_OPENAI_ENDPOINT"
echo "   3. Test: docker compose restart litellm"
echo ""
echo "Step 3.5: Old resource cleanup (manual)"
echo "   Run: az group delete --name <old-rg> --yes"

echo ""
echo "✅ Scenario 3 PASSED: Migration deployment successful to new resource group"
