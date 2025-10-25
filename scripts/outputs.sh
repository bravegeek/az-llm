#!/bin/bash
# T024: Extract deployment outputs to .env.azure-foundry file
# Outputs: AI Services endpoint, resource IDs, model deployment details
set -euo pipefail

RESOURCE_GROUP=${1:?"ERROR: Resource group name required. Usage: ./scripts/outputs.sh <resource-group> [deployment-name]"}
DEPLOYMENT_NAME=${2:-""}

echo "📤 Extracting AI Foundry deployment outputs..."

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

# Extract outputs to JSON
echo "   Fetching deployment outputs..."
az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --query 'properties.outputs' \
  --output json > /tmp/ai-foundry-outputs.json

if [ $? -ne 0 ]; then
    echo "❌ Failed to fetch deployment outputs"
    exit 1
fi

# Parse output values
AI_SERVICES_ID=$(jq -r '.aiServicesResourceId.value' /tmp/ai-foundry-outputs.json)
PROJECT_ID=$(jq -r '.projectResourceId.value' /tmp/ai-foundry-outputs.json)
ENDPOINT=$(jq -r '.aiServicesEndpoint.value' /tmp/ai-foundry-outputs.json)

# GPT-4 deployment
GPT4_DEPLOYMENT=$(jq -r '.gpt4Deployment.value.deploymentName' /tmp/ai-foundry-outputs.json)
GPT4_MODEL=$(jq -r '.gpt4Deployment.value.model' /tmp/ai-foundry-outputs.json)
GPT4_VERSION=$(jq -r '.gpt4Deployment.value.version' /tmp/ai-foundry-outputs.json)
GPT4_CAPACITY=$(jq -r '.gpt4Deployment.value.capacity' /tmp/ai-foundry-outputs.json)

# GPT-4o-mini deployment
GPT4O_MINI_DEPLOYMENT=$(jq -r '.gpt4oMiniDeployment.value.deploymentName' /tmp/ai-foundry-outputs.json)
GPT4O_MINI_MODEL=$(jq -r '.gpt4oMiniDeployment.value.model' /tmp/ai-foundry-outputs.json)
GPT4O_MINI_VERSION=$(jq -r '.gpt4oMiniDeployment.value.version' /tmp/ai-foundry-outputs.json)
GPT4O_MINI_CAPACITY=$(jq -r '.gpt4oMiniDeployment.value.capacity' /tmp/ai-foundry-outputs.json)

# GPT-4o deployment
GPT4O_DEPLOYMENT=$(jq -r '.gpt4oDeployment.value.deploymentName' /tmp/ai-foundry-outputs.json)
GPT4O_MODEL=$(jq -r '.gpt4oDeployment.value.model' /tmp/ai-foundry-outputs.json)
GPT4O_VERSION=$(jq -r '.gpt4oDeployment.value.version' /tmp/ai-foundry-outputs.json)
GPT4O_CAPACITY=$(jq -r '.gpt4oDeployment.value.capacity' /tmp/ai-foundry-outputs.json)

# Serverless model placeholders
FLUX_STATUS=$(jq -r '.fluxDeployment.value.deploymentStatus' /tmp/ai-foundry-outputs.json)
FLUX_MODEL=$(jq -r '.fluxDeployment.value.model' /tmp/ai-foundry-outputs.json)
DEEPSEEK_STATUS=$(jq -r '.deepseekDeployment.value.deploymentStatus' /tmp/ai-foundry-outputs.json)
DEEPSEEK_MODEL=$(jq -r '.deepseekDeployment.value.model' /tmp/ai-foundry-outputs.json)

# Generate .env file
ENV_FILE=".env.azure-foundry"
cat > "$ENV_FILE" <<EOF
# Azure AI Foundry Configuration (Generated: $(date))
# Resource Group: $RESOURCE_GROUP
# Deployment: $DEPLOYMENT_NAME

# Infrastructure Resource IDs
AI_SERVICES_ID=$AI_SERVICES_ID
PROJECT_ID=$PROJECT_ID

# AI Services Endpoint
AI_SERVICES_ENDPOINT=$ENDPOINT

# Standard Model Deployments (Bicep-deployed, 200K TPM total)

# GPT-4 (50K TPM)
GPT4_DEPLOYMENT_NAME=$GPT4_DEPLOYMENT
GPT4_MODEL=$GPT4_MODEL
GPT4_VERSION=$GPT4_VERSION
GPT4_CAPACITY=$GPT4_CAPACITY
GPT4_ENDPOINT=$ENDPOINT

# GPT-4o-mini (100K TPM)
GPT4O_MINI_DEPLOYMENT_NAME=$GPT4O_MINI_DEPLOYMENT
GPT4O_MINI_MODEL=$GPT4O_MINI_MODEL
GPT4O_MINI_VERSION=$GPT4O_MINI_VERSION
GPT4O_MINI_CAPACITY=$GPT4O_MINI_CAPACITY
GPT4O_MINI_ENDPOINT=$ENDPOINT

# GPT-4o (50K TPM)
GPT4O_DEPLOYMENT_NAME=$GPT4O_DEPLOYMENT
GPT4O_MODEL=$GPT4O_MODEL
GPT4O_VERSION=$GPT4O_VERSION
GPT4O_CAPACITY=$GPT4O_CAPACITY
GPT4O_ENDPOINT=$ENDPOINT

# Serverless Models (Manual Deployment Required)
# Deploy these via Azure AI Foundry portal: https://ai.azure.com

# FLUX-1.1-pro (Serverless)
FLUX_DEPLOYMENT_STATUS=$FLUX_STATUS
FLUX_MODEL=$FLUX_MODEL
FLUX_ENDPOINT=<manual-deployment>
FLUX_KEY=<manual-deployment>

# DeepSeek-V3.1 (Serverless)
DEEPSEEK_DEPLOYMENT_STATUS=$DEEPSEEK_STATUS
DEEPSEEK_MODEL=$DEEPSEEK_MODEL
DEEPSEEK_ENDPOINT=<manual-deployment>
DEEPSEEK_KEY=<manual-deployment>
EOF

echo ""
echo "✅ Outputs extracted to: $ENV_FILE"
echo ""
echo "📄 Generated .env file contents:"
echo "   - AI Services Resource ID"
echo "   - Project Resource ID"
echo "   - Endpoint URL"
echo "   - 3 standard model deployments (gpt-4, gpt-4o-mini, gpt-4o)"
echo "   - 2 serverless model placeholders (FLUX-1.1-pro, DeepSeek-V3.1)"
echo ""
echo "⚠️  Remember to deploy serverless models manually:"
echo "   1. Navigate to https://ai.azure.com"
echo "   2. Select your project"
echo "   3. Go to Model Catalog"
echo "   4. Search and deploy FLUX-1.1-pro and DeepSeek-V3.1"
echo "   5. Update $ENV_FILE with their endpoints and keys"
echo ""
echo "💡 Source this file in your shell:"
echo "   source $ENV_FILE"
