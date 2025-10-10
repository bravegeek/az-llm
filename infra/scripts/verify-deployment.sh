#!/usr/bin/env bash
#
# T025: Post-Deployment Verification Script
# Verifies all resources are deployed correctly and accessible
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
ENVIRONMENT="dev"
RESOURCE_GROUP=""

usage() {
    cat << EOF
Usage: $0 --environment <env> --resource-group <rg-name>

Options:
    --environment     Environment name (dev, staging, prod)
    --resource-group  Resource group name to verify
    -h, --help       Show this help message

Example:
    $0 --environment dev --resource-group rg-az-llm-dev
EOF
    exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Validate required arguments
if [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}ERROR: --resource-group is required${NC}"
    usage
fi

echo -e "${BLUE}=== Azure Infrastructure Deployment Verification ===${NC}"
echo -e "Environment: ${YELLOW}$ENVIRONMENT${NC}"
echo -e "Resource Group: ${YELLOW}$RESOURCE_GROUP${NC}"
echo

# Check if resource group exists
echo -n "Checking resource group exists... "
if az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${RED}FAIL${NC}"
    echo "Resource group '$RESOURCE_GROUP' does not exist"
    exit 1
fi

# Initialize counters
PASSED=0
FAILED=0

verify_resource() {
    local resource_name="$1"
    local resource_type="$2"
    local check_command="$3"

    echo -n "Verifying $resource_name ($resource_type)... "
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        ((FAILED++))
        return 1
    fi
}

# Verify VNet
VNET_NAME="vnet-az-llm-$ENVIRONMENT"
verify_resource "Virtual Network" "Microsoft.Network/virtualNetworks" \
    "az network vnet show --resource-group '$RESOURCE_GROUP' --name '$VNET_NAME'"

# Verify VNet subnet
SUBNET_NAME="snet-appservice-integration"
verify_resource "App Service Subnet" "Microsoft.Network/virtualNetworks/subnets" \
    "az network vnet subnet show --resource-group '$RESOURCE_GROUP' --vnet-name '$VNET_NAME' --name '$SUBNET_NAME'"

# Verify OpenAI Service
OPENAI_NAME="oai-az-llm-$ENVIRONMENT"
verify_resource "Azure OpenAI Service" "Microsoft.CognitiveServices/accounts" \
    "az cognitiveservices account show --resource-group '$RESOURCE_GROUP' --name '$OPENAI_NAME'"

# Verify OpenAI deployments
echo "Checking OpenAI model deployments:"
for model in "gpt-4o" "gpt-35-turbo" "dall-e-3"; do
    echo -n "  - $model... "
    if az cognitiveservices account deployment show \
        --resource-group "$RESOURCE_GROUP" \
        --name "$OPENAI_NAME" \
        --deployment-name "$model" > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        ((FAILED++))
    fi
done

# Verify App Service Plan
ASP_NAME="asp-az-llm-$ENVIRONMENT"
verify_resource "App Service Plan" "Microsoft.Web/serverfarms" \
    "az appservice plan show --resource-group '$RESOURCE_GROUP' --name '$ASP_NAME'"

# Verify App Service
APP_NAME="app-az-llm-backend-$ENVIRONMENT"
verify_resource "App Service" "Microsoft.Web/sites" \
    "az webapp show --resource-group '$RESOURCE_GROUP' --name '$APP_NAME'"

# Verify App Service has managed identity
echo -n "Checking App Service managed identity... "
IDENTITY=$(az webapp identity show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query principalId -o tsv 2>/dev/null || echo "")
if [[ -n "$IDENTITY" ]]; then
    echo -e "${GREEN}OK${NC} (Principal ID: $IDENTITY)"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

# Verify App Service VNet integration
echo -n "Checking App Service VNet integration... "
VNET_INTEGRATION=$(az webapp vnet-integration list --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query "[0].id" -o tsv 2>/dev/null || echo "")
if [[ -n "$VNET_INTEGRATION" ]]; then
    echo -e "${GREEN}OK${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

# Verify Static Web App
SWA_NAME="swa-az-llm-frontend-$ENVIRONMENT"
verify_resource "Static Web App" "Microsoft.Web/staticSites" \
    "az staticwebapp show --resource-group '$RESOURCE_GROUP' --name '$SWA_NAME'"

# Verify Log Analytics Workspace
LAW_NAME="law-az-llm-$ENVIRONMENT"
verify_resource "Log Analytics Workspace" "Microsoft.OperationalInsights/workspaces" \
    "az monitor log-analytics workspace show --resource-group '$RESOURCE_GROUP' --workspace-name '$LAW_NAME'"

# Verify Application Insights
APPI_NAME="appi-az-llm-$ENVIRONMENT"
verify_resource "Application Insights" "Microsoft.Insights/components" \
    "az monitor app-insights component show --resource-group '$RESOURCE_GROUP' --app '$APPI_NAME'"

# Verify RBAC role assignment
echo -n "Checking OpenAI role assignment for App Service... "
OPENAI_RESOURCE_ID=$(az cognitiveservices account show --resource-group "$RESOURCE_GROUP" --name "$OPENAI_NAME" --query id -o tsv)
ROLE_ASSIGNMENT=$(az role assignment list --assignee "$IDENTITY" --scope "$OPENAI_RESOURCE_ID" --query "[?roleDefinitionName=='Cognitive Services OpenAI User'].id" -o tsv 2>/dev/null || echo "")
if [[ -n "$ROLE_ASSIGNMENT" ]]; then
    echo -e "${GREEN}OK${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

# Get deployment outputs
echo
echo -e "${BLUE}=== Deployment Outputs ===${NC}"
DEPLOYMENT_NAME=$(az deployment group list --resource-group "$RESOURCE_GROUP" --query "[?contains(name, 'az-llm-infra')].name | [0]" -o tsv)
if [[ -n "$DEPLOYMENT_NAME" ]]; then
    az deployment group show --resource-group "$RESOURCE_GROUP" --name "$DEPLOYMENT_NAME" --query properties.outputs -o table
fi

# Summary
echo
echo -e "${BLUE}=== Verification Summary ===${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo
    echo -e "${GREEN}All verifications passed!${NC}"
    exit 0
else
    echo
    echo -e "${RED}Some verifications failed. Please review the errors above.${NC}"
    exit 1
fi
