#!/usr/bin/env bash
#
# T011: Integration Test - Multi-Environment Deployment
# Test scenario: Deploy dev, staging, prod with same SKUs
# Based on quickstart.md Scenario 3
# Expected to FAIL initially (no deployment scripts exist yet)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PARAMS_DIR="$REPO_ROOT/infra/parameters"

echo "=== Integration Test: Multi-Environment Deployment ==="
echo

# Check parameter files for all environments exist
ENVS=("dev" "staging" "prod")
MISSING=0

for env in "${ENVS[@]}"; do
    PARAM_FILE="$PARAMS_DIR/${env}.bicepparam"
    echo -n "Checking ${env}.bicepparam... "

    if [ ! -f "$PARAM_FILE" ]; then
        echo "MISSING"
        MISSING=1
        continue
    fi

    # Verify SKU consistency (should all be B1 per clarification)
    if grep -q "name:.*'B1'" "$PARAM_FILE" || grep -q 'name: "B1"' "$PARAM_FILE"; then
        echo "OK (SKU: B1)"
    else
        echo "WARNING (SKU not B1 or not found)"
    fi
done

if [ $MISSING -eq 1 ]; then
    echo
    echo "Multi-environment test FAILED: Missing parameter files"
    exit 1
fi

echo
echo "Multi-environment test structure PASSED"
echo "(Actual multi-environment deployment will be tested in T034)"
exit 0
