#!/usr/bin/env bash
#
# T027: Cleanup Script
# Safely deletes Azure resource groups with confirmation prompts
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
ENVIRONMENT=""
RESOURCE_GROUP=""
FORCE=false

usage() {
    cat << EOF
Usage: $0 --environment <env> [--force]
   or: $0 --resource-group <rg-name> [--force]

Options:
    --environment     Environment name (dev, staging, prod)
    --resource-group  Resource group name to delete
    --force          Skip confirmation prompts (DANGEROUS)
    -h, --help       Show this help message

Examples:
    # Delete dev environment (with confirmation)
    $0 --environment dev

    # Delete specific resource group (with confirmation)
    $0 --resource-group rg-az-llm-custom

    # Force delete without prompts (use with caution)
    $0 --environment dev --force

WARNINGS:
    - This script PERMANENTLY DELETES all resources in the resource group
    - This action CANNOT BE UNDONE
    - Use --force flag only in automated scenarios
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
        --force)
            FORCE=true
            shift
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

# Validate arguments
if [[ -z "$ENVIRONMENT" ]] && [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}ERROR: Either --environment or --resource-group is required${NC}"
    usage
fi

if [[ -n "$ENVIRONMENT" ]] && [[ -n "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}ERROR: Cannot specify both --environment and --resource-group${NC}"
    usage
fi

# Determine resource group name
if [[ -n "$ENVIRONMENT" ]]; then
    RESOURCE_GROUP="rg-az-llm-$ENVIRONMENT"
fi

echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                   DANGER ZONE                              ║${NC}"
echo -e "${RED}║  This script will DELETE ALL resources in the following:  ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
echo
echo -e "Resource Group: ${YELLOW}$RESOURCE_GROUP${NC}"
echo

# Check if resource group exists
if ! az group show --name "$RESOURCE_GROUP" > /dev/null 2>&1; then
    echo -e "${YELLOW}Resource group '$RESOURCE_GROUP' does not exist.${NC}"
    echo "Nothing to delete."
    exit 0
fi

# List resources in the group
echo -e "${BLUE}Resources that will be deleted:${NC}"
az resource list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name, Type:type}" -o table
echo

# Show estimated cost impact (if resources exist)
RESOURCE_COUNT=$(az resource list --resource-group "$RESOURCE_GROUP" --query "length([])" -o tsv)
echo -e "${YELLOW}Total resources to delete: $RESOURCE_COUNT${NC}"
echo

# Protection for production environment
if [[ "$ENVIRONMENT" == "prod" ]] || [[ "$RESOURCE_GROUP" == *"prod"* ]]; then
    echo -e "${RED}WARNING: This appears to be a PRODUCTION environment!${NC}"
    echo -e "${RED}Deleting production resources requires additional confirmation.${NC}"
    echo

    if [[ "$FORCE" == false ]]; then
        read -rp "Type 'DELETE PRODUCTION' to confirm: " PROD_CONFIRM
        if [[ "$PROD_CONFIRM" != "DELETE PRODUCTION" ]]; then
            echo -e "${GREEN}Deletion cancelled.${NC}"
            exit 0
        fi
    else
        echo -e "${RED}FORCE MODE: Skipping production confirmation (DANGEROUS!)${NC}"
    fi
fi

# Confirmation prompt
if [[ "$FORCE" == false ]]; then
    echo -e "${YELLOW}This action CANNOT be undone.${NC}"
    read -rp "Are you sure you want to delete '$RESOURCE_GROUP'? (yes/no): " CONFIRM

    if [[ "$CONFIRM" != "yes" ]]; then
        echo -e "${GREEN}Deletion cancelled.${NC}"
        exit 0
    fi

    # Second confirmation
    read -rp "Type the resource group name to confirm: " RG_CONFIRM
    if [[ "$RG_CONFIRM" != "$RESOURCE_GROUP" ]]; then
        echo -e "${RED}Resource group name mismatch. Deletion cancelled.${NC}"
        exit 1
    fi
else
    echo -e "${RED}FORCE MODE: Skipping confirmation prompts${NC}"
fi

# Perform deletion
echo
echo -e "${BLUE}Starting deletion of resource group '$RESOURCE_GROUP'...${NC}"
echo "This may take several minutes..."
echo

START_TIME=$(date +%s)

if az group delete --name "$RESOURCE_GROUP" --yes --no-wait; then
    echo -e "${GREEN}Deletion request submitted successfully.${NC}"
    echo
    echo "The resource group is being deleted in the background."
    echo "You can monitor the deletion status with:"
    echo -e "${BLUE}  az group show --name $RESOURCE_GROUP${NC}"
    echo
    echo "Or wait for completion with:"
    echo -e "${BLUE}  az group wait --name $RESOURCE_GROUP --deleted${NC}"

    # Wait for deletion if in force mode (for automation)
    if [[ "$FORCE" == true ]]; then
        echo
        echo "Waiting for deletion to complete..."
        if az group wait --name "$RESOURCE_GROUP" --deleted --timeout 1800 2>/dev/null; then
            END_TIME=$(date +%s)
            DURATION=$((END_TIME - START_TIME))
            echo -e "${GREEN}Resource group deleted successfully in ${DURATION}s.${NC}"
        else
            echo -e "${YELLOW}Deletion is taking longer than expected. Check Azure Portal.${NC}"
        fi
    fi

    exit 0
else
    echo -e "${RED}Failed to submit deletion request.${NC}"
    echo "Please check Azure CLI authentication and permissions."
    exit 1
fi
