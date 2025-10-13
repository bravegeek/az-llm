#!/usr/bin/env bash
#
# T026: Security Validation Script
# Validates security compliance and best practices
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

echo -e "${BLUE}=== Azure Infrastructure Security Validation ===${NC}"
echo -e "Environment: ${YELLOW}$ENVIRONMENT${NC}"
echo -e "Resource Group: ${YELLOW}$RESOURCE_GROUP${NC}"
echo

# Initialize counters
PASSED=0
FAILED=0
WARNINGS=0

check_security() {
    local check_name="$1"
    local check_command="$2"
    local severity="${3:-FAIL}"  # FAIL or WARN

    echo -n "Checking $check_name... "
    if eval "$check_command" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
        return 0
    else
        if [[ "$severity" == "WARN" ]]; then
            echo -e "${YELLOW}WARN${NC}"
            ((WARNINGS++))
        else
            echo -e "${RED}FAIL${NC}"
            ((FAILED++))
        fi
        return 1
    fi
}

# App Service security checks
APP_NAME="app-az-llm-backend-$ENVIRONMENT"
echo -e "${BLUE}App Service Security:${NC}"

# Check HTTPS only
echo -n "  HTTPS only enforcement... "
HTTPS_ONLY=$(az webapp show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query httpsOnly -o tsv)
if [[ "$HTTPS_ONLY" == "true" ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC} (HTTPS not enforced)"
    ((FAILED++))
fi

# Check TLS version
echo -n "  Minimum TLS version 1.2... "
TLS_VERSION=$(az webapp config show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query minTlsVersion -o tsv)
if [[ "$TLS_VERSION" == "1.2" ]] || [[ "$TLS_VERSION" == "1.3" ]]; then
    echo -e "${GREEN}PASS${NC} (TLS $TLS_VERSION)"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC} (TLS version: $TLS_VERSION)"
    ((FAILED++))
fi

# Check FTP disabled
echo -n "  FTP disabled... "
FTP_STATE=$(az webapp config show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query ftpsState -o tsv)
if [[ "$FTP_STATE" == "Disabled" ]] || [[ "$FTP_STATE" == "FtpsOnly" ]]; then
    echo -e "${GREEN}PASS${NC} ($FTP_STATE)"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC} (FTP state: $FTP_STATE)"
    ((FAILED++))
fi

# Check managed identity enabled
echo -n "  Managed identity enabled... "
IDENTITY=$(az webapp identity show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query principalId -o tsv 2>/dev/null || echo "")
if [[ -n "$IDENTITY" ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

# Check VNet integration
echo -n "  VNet integration configured... "
VNET_INTEGRATION=$(az webapp vnet-integration list --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query "[0].id" -o tsv 2>/dev/null || echo "")
if [[ -n "$VNET_INTEGRATION" ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}WARN${NC} (No VNet integration)"
    ((WARNINGS++))
fi

# Check remote debugging disabled
echo -n "  Remote debugging disabled... "
REMOTE_DEBUG=$(az webapp config show --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query remoteDebuggingEnabled -o tsv)
if [[ "$REMOTE_DEBUG" == "false" ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}WARN${NC} (Remote debugging enabled)"
    ((WARNINGS++))
fi

echo

# OpenAI Service security checks
OPENAI_NAME="oai-az-llm-$ENVIRONMENT"
echo -e "${BLUE}Azure OpenAI Security:${NC}"

# Check public network access (allowed in hybrid model)
echo -n "  Public network access... "
PUBLIC_ACCESS=$(az cognitiveservices account show --resource-group "$RESOURCE_GROUP" --name "$OPENAI_NAME" --query "properties.publicNetworkAccess" -o tsv)
if [[ "$PUBLIC_ACCESS" == "Enabled" ]]; then
    echo -e "${GREEN}PASS${NC} (Hybrid networking with managed identity)"
    ((PASSED++))
else
    echo -e "${YELLOW}WARN${NC} (Public access: $PUBLIC_ACCESS)"
    ((WARNINGS++))
fi

# Check RBAC role assignment exists
echo -n "  RBAC role assignment... "
OPENAI_RESOURCE_ID=$(az cognitiveservices account show --resource-group "$RESOURCE_GROUP" --name "$OPENAI_NAME" --query id -o tsv)
ROLE_ASSIGNMENT=$(az role assignment list --assignee "$IDENTITY" --scope "$OPENAI_RESOURCE_ID" --query "[?roleDefinitionName=='Cognitive Services OpenAI User'].id" -o tsv 2>/dev/null || echo "")
if [[ -n "$ROLE_ASSIGNMENT" ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC} (No OpenAI User role assignment)"
    ((FAILED++))
fi

# Check for key-based access in app settings (should use managed identity)
echo -n "  No API keys in app settings... "
API_KEY_SETTINGS=$(az webapp config appsettings list --resource-group "$RESOURCE_GROUP" --name "$APP_NAME" --query "[?contains(name, 'API_KEY') || contains(name, 'OPENAI_KEY')].name" -o tsv 2>/dev/null || echo "")
if [[ -z "$API_KEY_SETTINGS" ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC} (Found API key settings: $API_KEY_SETTINGS)"
    ((FAILED++))
fi

echo

# Static Web App security checks
SWA_NAME="swa-az-llm-frontend-$ENVIRONMENT"
echo -e "${BLUE}Static Web App Security:${NC}"

# Check if Static Web App exists
echo -n "  Static Web App deployed... "
if az staticwebapp show --resource-group "$RESOURCE_GROUP" --name "$SWA_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

echo

# Monitoring and logging checks
LAW_NAME="law-az-llm-$ENVIRONMENT"
APPI_NAME="appi-az-llm-$ENVIRONMENT"
echo -e "${BLUE}Monitoring & Logging:${NC}"

# Check Log Analytics Workspace exists
echo -n "  Log Analytics Workspace... "
if az monitor log-analytics workspace show --resource-group "$RESOURCE_GROUP" --workspace-name "$LAW_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

# Check Application Insights exists
echo -n "  Application Insights... "
if az monitor app-insights component show --resource-group "$RESOURCE_GROUP" --app "$APPI_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

# Check Application Insights linked to Log Analytics
echo -n "  Application Insights workspace-based... "
WORKSPACE_ID=$(az monitor app-insights component show --resource-group "$RESOURCE_GROUP" --app "$APPI_NAME" --query workspaceResourceId -o tsv 2>/dev/null || echo "")
if [[ -n "$WORKSPACE_ID" ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}WARN${NC} (Not workspace-based)"
    ((WARNINGS++))
fi

echo

# Network security checks
VNET_NAME="vnet-az-llm-$ENVIRONMENT"
echo -e "${BLUE}Network Security:${NC}"

# Check VNet exists
echo -n "  Virtual Network deployed... "
if az network vnet show --resource-group "$RESOURCE_GROUP" --name "$VNET_NAME" > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${RED}FAIL${NC}"
    ((FAILED++))
fi

# Check subnet delegation
echo -n "  Subnet delegation configured... "
SUBNET_NAME="snet-appservice-integration"
DELEGATION=$(az network vnet subnet show --resource-group "$RESOURCE_GROUP" --vnet-name "$VNET_NAME" --name "$SUBNET_NAME" --query "delegations[0].serviceName" -o tsv 2>/dev/null || echo "")
if [[ "$DELEGATION" == "Microsoft.Web/serverFarms" ]]; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}WARN${NC} (Delegation: $DELEGATION)"
    ((WARNINGS++))
fi

echo

# Resource tagging checks
echo -e "${BLUE}Resource Tagging:${NC}"

# Check tags on resource group
echo -n "  Resource group tags... "
TAGS=$(az group show --name "$RESOURCE_GROUP" --query "tags" -o json 2>/dev/null || echo "{}")
if echo "$TAGS" | grep -q "Environment"; then
    echo -e "${GREEN}PASS${NC}"
    ((PASSED++))
else
    echo -e "${YELLOW}WARN${NC} (No Environment tag)"
    ((WARNINGS++))
fi

echo

# Summary
echo -e "${BLUE}=== Security Validation Summary ===${NC}"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [[ $FAILED -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
    echo
    echo -e "${GREEN}All security validations passed!${NC}"
    exit 0
elif [[ $FAILED -eq 0 ]]; then
    echo
    echo -e "${YELLOW}Security validations passed with warnings. Review warnings above.${NC}"
    exit 0
else
    echo
    echo -e "${RED}Security validation failed. Please review the errors above.${NC}"
    exit 1
fi
