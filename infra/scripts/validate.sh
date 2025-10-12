#!/usr/bin/env bash
#
# T020: Deployment Validation Script
# Validates Bicep templates and shows what-if deployment changes
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INFRA_DIR="$REPO_ROOT/infra"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
ENVIRONMENT=""

usage() {
    echo "Usage: $0 --environment <dev|staging|prod>"
    echo
    echo "This script validates Bicep templates and shows what-if deployment changes"
    exit 1
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
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
RG_NAME="rg-${PROJECT}-${ENVIRONMENT}"
MAIN_BICEP="$INFRA_DIR/main.bicep"
PARAM_FILE="$INFRA_DIR/parameters/${ENVIRONMENT}.bicepparam"

echo "=== Azure Infrastructure Validation ==="
echo "Environment: $ENVIRONMENT"
echo "Resource Group: $RG_NAME"
echo

# Check files exist
if [ ! -f "$MAIN_BICEP" ]; then
    echo -e "${RED}Error: main.bicep not found at $MAIN_BICEP${NC}"
    exit 1
fi

if [ ! -f "$PARAM_FILE" ]; then
    echo -e "${RED}Error: Parameter file not found at $PARAM_FILE${NC}"
    exit 1
fi

# 1. Bicep Linting
echo "Step 1: Bicep Linting"
echo "---"
if az bicep lint --file "$MAIN_BICEP" 2>&1 | grep -q "Error\|error"; then
    echo -e "${RED}✗ Linting failed${NC}"
    az bicep lint --file "$MAIN_BICEP" || true
    exit 1
else
    echo -e "${GREEN}✓ Linting passed${NC}"
fi
echo

# 2. Build Validation
echo "Step 2: Bicep Build Validation"
echo "---"
if az bicep build --file "$MAIN_BICEP" --stdout > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Build successful${NC}"
else
    echo -e "${RED}✗ Build failed${NC}"
    az bicep build --file "$MAIN_BICEP" 2>&1 || true
    exit 1
fi
echo

# 3. Parameter Validation
echo "Step 3: Parameter File Validation"
echo "---"
if [ -f "$PARAM_FILE" ]; then
    echo -e "${GREEN}✓ Parameter file exists${NC}"
    echo "Required parameters:"
    grep "^param " "$PARAM_FILE" | head -5
    echo "..."
else
    echo -e "${RED}✗ Parameter file missing${NC}"
    exit 1
fi
echo

# 4. What-If Deployment (requires resource group to exist)
echo "Step 4: What-If Deployment Analysis"
echo "---"
if az group show --name "$RG_NAME" > /dev/null 2>&1; then
    echo "Running what-if analysis (shows proposed changes)..."
    echo
    az deployment group what-if \
        --resource-group "$RG_NAME" \
        --template-file "$MAIN_BICEP" \
        --parameters "$PARAM_FILE" \
        --result-format FullResourcePayloads \
        2>&1 || echo -e "${YELLOW}Note: What-if may show warnings for new resources${NC}"
else
    echo -e "${YELLOW}Note: Resource group $RG_NAME does not exist${NC}"
    echo "      What-if analysis skipped (requires existing resource group)"
    echo "      Create resource group first, or run deploy.sh to create it automatically"
fi

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Validation complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo "Next step:"
echo "  infra/scripts/deploy.sh --environment $ENVIRONMENT"
