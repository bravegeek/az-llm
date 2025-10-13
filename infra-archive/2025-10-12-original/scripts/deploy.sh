#!/usr/bin/env bash
#
# T019: Deployment Orchestration Script
# Deploys Azure infrastructure for specified environment
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INFRA_DIR="$REPO_ROOT/infra"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
ENVIRONMENT=""
SKIP_VALIDATION=false

usage() {
    echo "Usage: $0 --environment <dev|staging|prod> [--skip-validation]"
    echo
    echo "Options:"
    echo "  --environment    Target environment (dev, staging, or prod)"
    echo "  --skip-validation Skip pre-deployment validation checks"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

if [ -z "$ENVIRONMENT" ]; then
    echo -e "${RED}Error: --environment is required${NC}"
    usage
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}Error: Environment must be dev, staging, or prod${NC}"
    exit 1
fi

# Configuration
PROJECT="az-llm"
LOCATION="eastus"
RG_NAME="rg-${PROJECT}-${ENVIRONMENT}"
MAIN_BICEP="$INFRA_DIR/main.bicep"
PARAM_FILE="$INFRA_DIR/parameters/${ENVIRONMENT}.bicepparam"
DEPLOYMENT_NAME="${PROJECT}-infra-$(date +%Y%m%d-%H%M%S)"

echo "=== Azure Infrastructure Deployment ==="
echo "Environment: $ENVIRONMENT"
echo "Resource Group: $RG_NAME"
echo "Location: $LOCATION"
echo "Deployment Name: $DEPLOYMENT_NAME"
echo

# Pre-flight checks
if [ ! -f "$MAIN_BICEP" ]; then
    echo -e "${RED}Error: main.bicep not found at $MAIN_BICEP${NC}"
    exit 1
fi

if [ ! -f "$PARAM_FILE" ]; then
    echo -e "${RED}Error: Parameter file not found at $PARAM_FILE${NC}"
    exit 1
fi

# Run validation unless skipped
if [ "$SKIP_VALIDATION" = false ]; then
    echo "Running pre-deployment validation..."
    if ! az bicep lint --file "$MAIN_BICEP" > /dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Bicep linting found issues${NC}"
        az bicep lint --file "$MAIN_BICEP" || true
    else
        echo -e "${GREEN}✓${NC} Bicep linting passed"
    fi
fi

# Ensure resource group exists
echo
echo "Checking resource group..."
if ! az group show --name "$RG_NAME" > /dev/null 2>&1; then
    echo "Creating resource group: $RG_NAME"
    az group create \
        --name "$RG_NAME" \
        --location "$LOCATION" \
        --tags Environment="$ENVIRONMENT" Project="$PROJECT"
else
    echo -e "${GREEN}✓${NC} Resource group exists"
fi

# Deploy infrastructure
echo
echo "Deploying infrastructure..."
echo "(This may take 5-10 minutes)"
echo

if az deployment group create \
    --resource-group "$RG_NAME" \
    --template-file "$MAIN_BICEP" \
    --parameters "$PARAM_FILE" \
    --name "$DEPLOYMENT_NAME" \
    --output json > "/tmp/${DEPLOYMENT_NAME}.json"; then

    echo
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Deployment completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo "Deployment name: $DEPLOYMENT_NAME"
    echo
    echo "Deployment outputs:"
    az deployment group show \
        --resource-group "$RG_NAME" \
        --name "$DEPLOYMENT_NAME" \
        --query "properties.outputs" \
        --output json | jq '.'

    echo
    echo "Next steps:"
    echo "  1. Run: infra/scripts/verify-deployment.sh --environment $ENVIRONMENT"
    echo "  2. Run: infra/scripts/verify-security.sh --environment $ENVIRONMENT"
    echo "  3. Deploy application code to App Service and Static Web App"

    exit 0
else
    echo
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}Deployment failed!${NC}"
    echo -e "${RED}========================================${NC}"
    echo
    echo "Check deployment errors:"
    echo "  az deployment group show \\"
    echo "    --resource-group $RG_NAME \\"
    echo "    --name $DEPLOYMENT_NAME \\"
    echo "    --query 'properties.error'"

    exit 1
fi
