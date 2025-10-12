#!/usr/bin/env bash
#
# T008: Deployment Validation Test
# Validates infra/main.bicep can deploy successfully (what-if mode)
# Expected to FAIL initially (templates don't exist yet)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAIN_BICEP="$REPO_ROOT/infra/main.bicep"
PARAMS_DIR="$REPO_ROOT/infra/parameters"

echo "=== Deployment Validation Test ==="
echo

# Check prerequisites
if [ ! -f "$MAIN_BICEP" ]; then
    echo "FAIL: main.bicep not found"
    exit 1
fi

# Test with dev parameters (dry-run only - no actual deployment)
PARAM_FILE="$PARAMS_DIR/dev.bicepparam"

if [ ! -f "$PARAM_FILE" ]; then
    echo "FAIL: dev.bicepparam not found"
    exit 1
fi

echo "Validating deployment with dev parameters..."
echo "(This is a dry-run validation - no resources will be created)"
echo

# Note: This test validates bicep compilation
# Actual Azure deployment validation requires auth and resource group
# For now, we validate the template can be built
if az bicep build --file "$MAIN_BICEP" --stdout > /dev/null 2>&1; then
    echo "Template validation: OK"
    echo
    echo "Deployment validation test PASSED"
    echo "(Full deployment validation requires Azure authentication)"
    exit 0
else
    echo "Template validation: FAIL"
    az bicep build --file "$MAIN_BICEP" 2>&1 || true
    echo
    echo "Deployment validation test FAILED"
    exit 1
fi
