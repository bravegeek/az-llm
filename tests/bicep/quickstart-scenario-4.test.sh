#!/bin/bash
# T013: Quickstart Scenario 4 - Quota Limit Failure Handling
# This is an INTEGRATION test requiring actual Azure resources
# Usage: ./tests/bicep/quickstart-scenario-4.test.sh <resource-group>

set -e

RESOURCE_GROUP=${1:-""}
if [ -z "$RESOURCE_GROUP" ]; then
    echo "⚠️  INTEGRATION TEST - requires Azure resources"
    echo ""
    echo "Usage: $0 <resource-group>"
    echo ""
    echo "This scenario validates:"
    echo "  - Intentionally exceed quota (4.1)"
    echo "  - Verify failure behavior (4.2)"
    echo "  - Fix and retry (4.3)"
    echo ""
    echo "See: specs/003-create-a-minimal/quickstart.md#scenario-4"
    exit 0
fi

echo "🧪 Testing Scenario 4: Quota Limit Failure Handling"
echo "   Resource Group: $RESOURCE_GROUP"
echo ""

# This is a DESTRUCTIVE test - require confirmation
echo "⚠️  This test will:"
echo "   1. Temporarily modify parameters to exceed quota"
echo "   2. Attempt deployment (expected to fail)"
echo "   3. Restore original parameters"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Test cancelled"
    exit 0
fi

# 4.1 Backup and modify parameters to exceed quota
if [ ! -f infra/main.parameters.local.json ]; then
    echo "❌ infra/main.parameters.local.json not found"
    exit 1
fi

cp infra/main.parameters.local.json infra/main.parameters.local.json.backup
echo "✅ Parameters backed up"

echo ""
echo "⚠️  Manual step required:"
echo "   Edit infra/main.parameters.local.json"
echo "   Set gpt41CapacityTPM to 999999 (exceeds quota)"
echo "   Press Enter when done..."
read

# 4.2 Attempt deployment (should fail)
echo ""
echo "Step 4.2: Attempting deployment with exceeded quota..."
set +e  # Allow failure
./scripts/deploy.sh "$RESOURCE_GROUP" @infra/main.parameters.local.json
DEPLOY_EXIT_CODE=$?
set -e

if [ $DEPLOY_EXIT_CODE -eq 0 ]; then
    echo "❌ Deployment succeeded (expected to fail with QuotaExceeded)"
    mv infra/main.parameters.local.json.backup infra/main.parameters.local.json
    exit 1
fi

echo "✅ Deployment failed as expected"

# 4.3 Restore and retry
echo ""
echo "Step 4.3: Restoring original parameters and retrying..."
mv infra/main.parameters.local.json.backup infra/main.parameters.local.json
./scripts/deploy.sh "$RESOURCE_GROUP" @infra/main.parameters.local.json

echo ""
echo "✅ Scenario 4 PASSED: Quota failure handled gracefully, retry succeeded"
