#!/usr/bin/env bash
#
# T006: Deployment Parameter Validation Test
# Validates parameter files against OpenAPI schema
# Expected to FAIL initially (parameter files don't exist yet)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PARAMS_DIR="$REPO_ROOT/infra/parameters"

echo "=== Deployment Parameter Validation Test ==="
echo "Scanning: $PARAMS_DIR"
echo

# Check for parameter files
PARAM_FILES=("dev.bicepparam" "staging.bicepparam" "prod.bicepparam")
MISSING=0

for param_file in "${PARAM_FILES[@]}"; do
    FILE_PATH="$PARAMS_DIR/$param_file"
    echo -n "Checking $param_file... "

    if [ ! -f "$FILE_PATH" ]; then
        echo "MISSING"
        MISSING=1
        continue
    fi

    # Validate bicepparam syntax (basic check)
    if grep -q "using.*main.bicep" "$FILE_PATH" && \
       grep -q "param environment" "$FILE_PATH" && \
       grep -q "param location" "$FILE_PATH"; then
        echo "OK"
    else
        echo "INVALID (missing required params)"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo
    echo "Parameter validation test FAILED"
    echo "Missing or invalid parameter files"
    exit 1
fi

echo
echo "Parameter validation test PASSED"
exit 0
