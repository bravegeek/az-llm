#!/bin/bash
# T020: Deployment automation script
set -euo pipefail

RESOURCE_GROUP=${1:?"ERROR: Resource group name required. Usage: ./scripts/deploy.sh <resource-group> <parameters-file>"}
PARAMETERS_FILE=${2:?"ERROR: Parameters file required. Usage: ./scripts/deploy.sh <resource-group> <parameters-file>"}

echo "🚀 Deploying minimal Azure OpenAI infrastructure..."
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Parameters: $PARAMETERS_FILE"
echo ""

# Validate Azure CLI is logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged into Azure CLI. Run 'az login' first."
    exit 1
fi

# Deploy
DEPLOYMENT_NAME="main-$(date +%Y%m%d-%H%M%S)"
echo "📦 Starting deployment: $DEPLOYMENT_NAME"

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --template-file infra/main.bicep \
  --parameters "$PARAMETERS_FILE" \
  --output json > /tmp/deployment-${DEPLOYMENT_NAME}.json

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment complete!"
    echo ""
    echo "📊 Deployment Outputs:"
    jq -r '.properties.outputs | to_entries[] | "\(.key): \(.value.value)"' /tmp/deployment-${DEPLOYMENT_NAME}.json | \
        sed 's/apiKey: .*/apiKey: <redacted>/' 
    echo ""
    echo "💡 Run './scripts/outputs.sh $RESOURCE_GROUP $DEPLOYMENT_NAME' to extract outputs to .env file"
else
    echo "❌ Deployment failed"
    exit 1
fi
