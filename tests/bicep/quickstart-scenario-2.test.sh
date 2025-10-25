#!/bin/bash
# T026: Quickstart Scenario 2 - Validate 3 models with correct TPM (200K total)
set -e

echo "=== Quickstart Scenario 2: Validate Model Deployments and TPM ==="

RESOURCE_GROUP=${RESOURCE_GROUP:-""}
AI_SERVICES_NAME=${AI_SERVICES_NAME:-""}

if [ -z "$RESOURCE_GROUP" ] || [ -z "$AI_SERVICES_NAME" ]; then
    echo "⚠️  Skipping integration test (no deployment specified)"
    exit 0
fi

FAILED=0

# Expected models with TPM
EXPECTED_MODELS=(
    "gpt-4:50"
    "gpt-4o-mini:100"
    "gpt-4o:50"
)

echo "Validating 3 model deployments with 200K TPM total..."
echo ""

# Get all deployments
DEPLOYMENTS=$(az cognitiveservices account deployment list \
    --name "$AI_SERVICES_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --output json 2>/dev/null || echo "[]")

TOTAL_TPM=0

for expected in "${EXPECTED_MODELS[@]}"; do
    IFS=':' read -r model capacity <<< "$expected"

    # Find deployment with this model
    FOUND_CAPACITY=$(echo "$DEPLOYMENTS" | jq -r \
        ".[] | select(.properties.model.name==\"$model\") | .sku.capacity" | head -1)

    if [ -n "$FOUND_CAPACITY" ] && [ "$FOUND_CAPACITY" = "$capacity" ]; then
        echo "✅ $model: ${capacity}K TPM (correct)"
        TOTAL_TPM=$((TOTAL_TPM + capacity))
    elif [ -n "$FOUND_CAPACITY" ]; then
        echo "❌ $model: ${FOUND_CAPACITY}K TPM (expected: ${capacity}K)"
        FAILED=$((FAILED + 1))
        TOTAL_TPM=$((TOTAL_TPM + FOUND_CAPACITY))
    else
        echo "❌ $model: not found"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "Total TPM: ${TOTAL_TPM}K"

if [ "$TOTAL_TPM" -eq 200 ]; then
    echo "✅ Total TPM correct (200K)"
else
    echo "❌ Total TPM incorrect (expected: 200K, got: ${TOTAL_TPM}K)"
    FAILED=$((FAILED + 1))
fi

echo ""
if [ $FAILED -eq 0 ]; then
    echo "✅ Scenario 2 PASSED"
    exit 0
else
    echo "❌ Scenario 2 FAILED: $FAILED check(s) failed"
    exit 1
fi
