#!/usr/bin/env bash
#
# Azure Infrastructure Prerequisites Check
# Verifies Azure CLI and Bicep CLI are installed with minimum required versions
#

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Minimum required versions
MIN_AZ_CLI_VERSION="2.50.0"
MIN_BICEP_VERSION="0.20.0"

# Function to compare semantic versions
version_ge() {
    test "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2"
}

echo "=== Azure Infrastructure Prerequisites Check ==="
echo

# Check Azure CLI
echo -n "Checking Azure CLI... "
if ! command -v az &> /dev/null; then
    echo -e "${RED}FAIL${NC}"
    echo "Azure CLI is not installed."
    echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

AZ_VERSION=$(az version --query '\"azure-cli\"' -o tsv 2>/dev/null || echo "0.0.0")
if version_ge "$AZ_VERSION" "$MIN_AZ_CLI_VERSION"; then
    echo -e "${GREEN}OK${NC} (version $AZ_VERSION)"
else
    echo -e "${RED}FAIL${NC}"
    echo "Azure CLI version $AZ_VERSION is below minimum required $MIN_AZ_CLI_VERSION"
    echo "Update with: az upgrade"
    exit 1
fi

# Check Bicep CLI
echo -n "Checking Bicep CLI... "
if ! az bicep version &> /dev/null; then
    echo -e "${RED}FAIL${NC}"
    echo "Bicep CLI is not installed."
    echo "Install with: az bicep install"
    exit 1
fi

BICEP_VERSION=$(az bicep version 2>/dev/null | grep -oP 'Bicep CLI version \K[0-9.]+' || echo "0.0.0")
if version_ge "$BICEP_VERSION" "$MIN_BICEP_VERSION"; then
    echo -e "${GREEN}OK${NC} (version $BICEP_VERSION)"
else
    echo -e "${YELLOW}WARNING${NC}"
    echo "Bicep CLI version $BICEP_VERSION is below recommended $MIN_BICEP_VERSION"
    echo "Update with: az bicep upgrade"
fi

# Check Azure authentication
echo -n "Checking Azure authentication... "
if az account show &> /dev/null; then
    ACCOUNT_NAME=$(az account show --query 'name' -o tsv)
    echo -e "${GREEN}OK${NC} (logged in as: $ACCOUNT_NAME)"
else
    echo -e "${YELLOW}NOT LOGGED IN${NC}"
    echo "Run: az login"
    exit 1
fi

echo
echo -e "${GREEN}All prerequisites met!${NC}"
echo "Ready to deploy Azure infrastructure."
