#!/bin/bash
# T025: Quickstart Scenario 1 - Deploy fresh AI Foundry project
# Validates: AIServices + Project + 3 model deployments exist
set -e

echo "=== Quickstart Scenario 1: Validate AI Foundry Infrastructure ==="

RESOURCE_GROUP=${RESOURCE_GROUP:-""}
AI_SERVICES_NAME=${AI_SERVICES_NAME:-""}

if [ -z "$RESOURCE_GROUP" ] || [ -z "$AI_SERVICES_NAME" ]; then
    echo "⚠️  No deployment to validate (set RESOURCE_GROUP and AI_SERVICES_NAME env vars)"
    echo "   Skipping integration test (assumes no deployment exists yet)"
    exit 0
fi

echo "Testing deployment in:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  AI Services: $AI_SERVICES_NAME"
echo ""

FAILED=0

# 1. Verify AIServices account exists
echo "1/4 Checking AIServices account..."
if az cognitiveservices account show \
    --name "$AI_SERVICES_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "kind" -o tsv 2>/dev/null | grep -q "AIServices"; then
    echo "✅ AIServices account exists with kind=AIServices"
else
    echo "❌ AIServices account not found or wrong kind"
    FAILED=$((FAILED + 1))
fi

# 2. Verify Project exists (as child resource)
echo "2/4 Checking AI Foundry Project..."
PROJECTS=$(az cognitiveservices account list \
    --resource-group "$RESOURCE_GROUP" \
    --query "[?kind=='Project'].name" -o tsv 2>/dev/null | wc -l)

if [ "$PROJECTS" -gt 0 ]; then
    PROJECT_NAME=$(az cognitiveservices account list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?kind=='Project'].name" -o tsv | head -1)
    echo "✅ AI Foundry Project exists: $PROJECT_NAME"
else
    echo "❌ No AI Foundry Project found"
    FAILED=$((FAILED + 1))
fi

# 3. Verify 3 model deployments exist
echo "3/4 Checking model deployments..."
DEPLOYMENT_COUNT=$(az cognitiveservices account deployment list \
    --name "$AI_SERVICES_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "length(@)" -o tsv 2>/dev/null || echo "0")

if [ "$DEPLOYMENT_COUNT" -eq 3 ]; then
    echo "✅ Found 3 model deployments"

    # List deployment details
    az cognitiveservices account deployment list \
        --name "$AI_SERVICES_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "[].{Name:name, Model:properties.model.name, Capacity:sku.capacity}" \
        -o table 2>/dev/null | while read -r line; do
        echo "   $line"
    done
else
    echo "❌ Expected 3 deployments, found $DEPLOYMENT_COUNT"
    FAILED=$((FAILED + 1))
fi

# 4. Verify deployment provisioning state
echo "4/4 Checking provisioning state..."
PROVISIONING_STATE=$(az cognitiveservices account show \
    --name "$AI_SERVICES_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.provisioningState" -o tsv 2>/dev/null || echo "Unknown")

if [ "$PROVISIONING_STATE" = "Succeeded" ]; then
    echo "✅ Provisioning state: Succeeded"
else
    echo "❌ Provisioning state: $PROVISIONING_STATE (expected: Succeeded)"
    FAILED=$((FAILED + 1))
fi

echo ""
if [ $FAILED -eq 0 ]; then
    echo "✅ Scenario 1 PASSED: All infrastructure components validated"
    exit 0
else
    echo "❌ Scenario 1 FAILED: $FAILED check(s) failed"
    exit 1
fi
