#!/bin/bash
# T022: Extract deployment outputs to .env file
set -euo pipefail

RESOURCE_GROUP=${1:?"ERROR: Resource group name required. Usage: ./scripts/outputs.sh <resource-group> [deployment-name]"}
DEPLOYMENT_NAME=${2:-""}

echo "📤 Extracting deployment outputs..."

# Find latest deployment if name not specified
if [ -z "$DEPLOYMENT_NAME" ]; then
    DEPLOYMENT_NAME=$(az deployment group list \
        --resource-group "$RESOURCE_GROUP" \
        --query "[?starts_with(name, 'main-')] | sort_by(@, &properties.timestamp) | [-1].name" \
        -o tsv)
    
    if [ -z "$DEPLOYMENT_NAME" ]; then
        echo "❌ No deployments found starting with 'main-' in resource group $RESOURCE_GROUP"
        exit 1
    fi
    echo "   Using latest deployment: $DEPLOYMENT_NAME"
fi

# Extract outputs
az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --query 'properties.outputs' \
  --output json > /tmp/outputs.json

# Parse values
ENDPOINT=$(jq -r '.endpoint.value' /tmp/outputs.json)
API_KEY=$(jq -r '.apiKey.value' /tmp/outputs.json)
DEPLOYMENTS=($(jq -r '.deploymentNames.value[]' /tmp/outputs.json))

if [ ${#DEPLOYMENTS[@]} -ne 5 ]; then
    echo "❌ Expected 5 model deployments, found ${#DEPLOYMENTS[@]}"
    exit 1
fi

# Generate .env file
cat > .env.azure-openai <<EOF
# Azure OpenAI Configuration (generated $(date))
AZURE_OPENAI_ENDPOINT=$ENDPOINT
AZURE_API_KEY=$API_KEY

# Model Deployment Names (5 models)
GPT41_DEPLOYMENT_NAME=${DEPLOYMENTS[0]}
GPT41_MINI_DEPLOYMENT_NAME=${DEPLOYMENTS[1]}
GPT4O_DEPLOYMENT_NAME=${DEPLOYMENTS[2]}
FLUX_DEPLOYMENT_NAME=${DEPLOYMENTS[3]}
DEEPSEEK_DEPLOYMENT_NAME=${DEPLOYMENTS[4]}
