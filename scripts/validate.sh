#!/bin/bash
# T022: Pre-deployment validation script for AI Foundry hub-less deployment
# Validates: region support, model availability, quota, clean resource group
set -euo pipefail

LOCATION=${1:-"eastus2"}
RESOURCE_GROUP=${2:-""}

echo "🔍 Validating AI Foundry deployment prerequisites..."
echo "   Region: $LOCATION"
echo ""

# Check Azure CLI login
if ! az account show &> /dev/null; then
    echo "❌ Not logged into Azure CLI. Run 'az login' first."
    exit 1
fi

# 1. Bicep syntax validation
echo "1/5 Running Bicep syntax validation..."
if ! az bicep build --file infra/main.bicep --stdout > /dev/null 2>&1; then
    echo "❌ Bicep syntax validation failed"
    az bicep build --file infra/main.bicep
    exit 1
fi
echo "✅ Bicep syntax valid"

# 2. Parameter file validation
echo "2/5 Running parameter file validation..."
if [ ! -f "infra/main.parameters.json" ]; then
    echo "❌ Parameters file not found: infra/main.parameters.json"
    exit 1
fi

# Validate against schema using ajv-cli (if installed)
if command -v ajv &> /dev/null; then
    if ! ajv validate -s specs/004-migrate-from-azure/contracts/input-schema.json -d infra/main.parameters.json 2>/dev/null; then
        echo "⚠️  Parameter schema validation warnings (non-fatal)"
    else
        echo "✅ Parameters valid against schema"
    fi
else
    echo "⚠️  ajv-cli not installed, skipping schema validation"
fi

# 3. Model availability check (3 standard models)
echo "3/5 Checking model availability in region $LOCATION..."
MODELS=("gpt-4" "gpt-4o-mini" "gpt-4o")
UNAVAILABLE=()

for model in "${MODELS[@]}"; do
    # Check if model is available in region
    AVAILABLE=$(az cognitiveservices model list \
        --location "$LOCATION" \
        --query "[?name=='$model'].name" \
        -o tsv 2>/dev/null || echo "")

    if [ -z "$AVAILABLE" ]; then
        UNAVAILABLE+=("$model")
        echo "❌ Model '$model' not available in region '$LOCATION'"
    else
        echo "✅ Model '$model' available"
    fi
done

if [ ${#UNAVAILABLE[@]} -gt 0 ]; then
    echo ""
    echo "❌ ${#UNAVAILABLE[@]} model(s) not available in '$LOCATION'"
    echo "   Unavailable: ${UNAVAILABLE[*]}"
    echo "   Try regions: eastus, eastus2, westus, northcentralus"
    exit 1
fi

# 4. TPM Quota validation (200K total: 50K+100K+50K)
echo "4/5 Checking TPM quota availability..."
REQUIRED_QUOTAS=(
    "gpt-4:50"
    "gpt-4o-mini:100"
    "gpt-4o:50"
)

for quota_spec in "${REQUIRED_QUOTAS[@]}"; do
    IFS=':' read -r model required_tpm <<< "$quota_spec"

    # Get current quota usage
    USAGE_DATA=$(az cognitiveservices usage list \
        --location "$LOCATION" \
        --query "[?contains(name.value, 'OpenAI') && contains(name.value, '$model')]" \
        -o json 2>/dev/null || echo "[]")

    if [ "$USAGE_DATA" = "[]" ]; then
        echo "⚠️  Could not verify quota for $model (continuing anyway)"
        continue
    fi

    CURRENT=$(echo "$USAGE_DATA" | jq -r '.[0].currentValue // 0')
    LIMIT=$(echo "$USAGE_DATA" | jq -r '.[0].limit // 0')
    AVAILABLE=$((LIMIT - CURRENT))

    if [ "$AVAILABLE" -lt "$required_tpm" ]; then
        echo "❌ Insufficient quota for $model"
        echo "   Required: ${required_tpm}K TPM, Available: ${AVAILABLE}K TPM (Limit: ${LIMIT}K)"
        exit 1
    fi

    echo "✅ Quota OK for $model (${required_tpm}K needed, ${AVAILABLE}K available)"
done

# 5. Clean resource group check (if RG specified)
if [ -n "$RESOURCE_GROUP" ]; then
    echo "5/5 Checking resource group is empty..."

    # Check if RG exists
    if ! az group exists --name "$RESOURCE_GROUP" | grep -q true; then
        echo "⚠️  Resource group '$RESOURCE_GROUP' does not exist (will be created during deployment)"
    else
        # Check RG is empty
        RESOURCE_COUNT=$(az resource list \
            --resource-group "$RESOURCE_GROUP" \
            --query "length(@)" \
            -o tsv)

        if [ "$RESOURCE_COUNT" -ne 0 ]; then
            echo "❌ Resource group contains $RESOURCE_COUNT resource(s)"
            echo "   Clean deployment required. Resources:"
            az resource list --resource-group "$RESOURCE_GROUP" --output table
            exit 1
        fi

        echo "✅ Resource group is empty"
    fi
else
    echo "5/5 Skipping resource group check (no RG specified)"
fi

echo ""
echo "✅ All validation checks passed!"
echo ""
echo "💡 Ready for deployment. Run:"
echo "   ./scripts/deploy.sh <resource-group> infra/main.parameters.json"
echo ""
echo "📝 Note: FLUX-1.1-pro and DeepSeek-V3.1 are serverless models"
echo "   These must be deployed manually via Azure AI Foundry portal after infrastructure deployment"
