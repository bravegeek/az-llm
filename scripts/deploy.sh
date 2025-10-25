#!/bin/bash
# T023: Deployment automation script for AI Foundry hub-less infrastructure
# Deploys: AIServices account + Project + 3 model deployments
set -euo pipefail

RESOURCE_GROUP=${1:?"ERROR: Resource group name required. Usage: ./scripts/deploy.sh <resource-group> <parameters-file>"}
PARAMETERS_FILE=${2:?"ERROR: Parameters file required. Usage: ./scripts/deploy.sh <resource-group> <parameters-file>"}

echo "🚀 Deploying AI Foundry hub-less infrastructure..."
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Parameters: $PARAMETERS_FILE"
echo ""

# Validate Azure CLI is logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged into Azure CLI. Run 'az login' first."
    exit 1
fi

# Validate parameters file exists
if [ ! -f "$PARAMETERS_FILE" ]; then
    echo "❌ Parameters file not found: $PARAMETERS_FILE"
    exit 1
fi

# Extract location from parameters for validation
LOCATION=$(jq -r '.parameters.location.value' "$PARAMETERS_FILE")

# Run pre-deployment validation
echo "🔍 Running pre-deployment validation..."
if ! ./scripts/validate.sh "$LOCATION" "$RESOURCE_GROUP"; then
    echo "❌ Validation failed. Fix issues and try again."
    exit 1
fi
echo ""

# Create resource group if it doesn't exist
if ! az group exists --name "$RESOURCE_GROUP" | grep -q true; then
    echo "📦 Creating resource group: $RESOURCE_GROUP"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
fi

# Deploy infrastructure
DEPLOYMENT_NAME="main-$(date +%Y%m%d-%H%M%S)"
echo "📦 Starting deployment: $DEPLOYMENT_NAME"
echo "   This may take 5-10 minutes..."
echo ""

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --template-file infra/main.bicep \
  --parameters "$PARAMETERS_FILE" \
  --output json > /tmp/deployment-${DEPLOYMENT_NAME}.json

DEPLOYMENT_STATUS=$?

if [ $DEPLOYMENT_STATUS -eq 0 ]; then
    PROVISIONING_STATE=$(jq -r '.properties.provisioningState' /tmp/deployment-${DEPLOYMENT_NAME}.json)

    if [ "$PROVISIONING_STATE" = "Succeeded" ]; then
        echo ""
        echo "✅ Deployment complete!"
        echo ""
        echo "📊 Deployment Outputs:"
        echo ""

        # Show AI Services info
        AI_SERVICES_ID=$(jq -r '.properties.outputs.aiServicesResourceId.value' /tmp/deployment-${DEPLOYMENT_NAME}.json)
        PROJECT_ID=$(jq -r '.properties.outputs.projectResourceId.value' /tmp/deployment-${DEPLOYMENT_NAME}.json)
        ENDPOINT=$(jq -r '.properties.outputs.aiServicesEndpoint.value' /tmp/deployment-${DEPLOYMENT_NAME}.json)

        echo "AI Services Resource ID:"
        echo "  $AI_SERVICES_ID"
        echo ""
        echo "Project Resource ID:"
        echo "  $PROJECT_ID"
        echo ""
        echo "Endpoint:"
        echo "  $ENDPOINT"
        echo ""

        # Show model deployments
        echo "Model Deployments:"
        for model in gpt4 gpt4oMini gpt4o; do
            DEPLOYMENT_NAME_VAR=$(jq -r ".properties.outputs.${model}Deployment.value.deploymentName" /tmp/deployment-${DEPLOYMENT_NAME}.json)
            MODEL_NAME=$(jq -r ".properties.outputs.${model}Deployment.value.model" /tmp/deployment-${DEPLOYMENT_NAME}.json)
            CAPACITY=$(jq -r ".properties.outputs.${model}Deployment.value.capacity" /tmp/deployment-${DEPLOYMENT_NAME}.json)
            echo "  - $DEPLOYMENT_NAME_VAR ($MODEL_NAME, ${CAPACITY}K TPM)"
        done
        echo ""

        # Show serverless model instructions
        echo "Serverless Models (Manual Deployment Required):"
        FLUX_INSTRUCTIONS=$(jq -r '.properties.outputs.fluxDeployment.value.deploymentInstructions' /tmp/deployment-${DEPLOYMENT_NAME}.json)
        echo "  - FLUX-1.1-pro: $FLUX_INSTRUCTIONS"
        DEEPSEEK_INSTRUCTIONS=$(jq -r '.properties.outputs.deepseekDeployment.value.deploymentInstructions' /tmp/deployment-${DEPLOYMENT_NAME}.json)
        echo "  - DeepSeek-V3.1: $DEEPSEEK_INSTRUCTIONS"
        echo ""

        echo "💡 Next steps:"
        echo "   1. Extract outputs: ./scripts/outputs.sh $RESOURCE_GROUP $DEPLOYMENT_NAME"
        echo "   2. Deploy serverless models via https://ai.azure.com"
        echo "   3. Run tests: bash tests/bicep/run-all-tests.sh"
    else
        echo "❌ Deployment failed with state: $PROVISIONING_STATE"
        jq -r '.properties.error' /tmp/deployment-${DEPLOYMENT_NAME}.json
        exit 1
    fi
else
    echo "❌ Deployment command failed"
    exit 1
fi
