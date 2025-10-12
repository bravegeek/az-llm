#!/usr/bin/env bash
#
# T005: Bicep Build Test
# Validates infra/main.bicep compiles without errors
# Expected to FAIL initially (main.bicep doesn't exist yet)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAIN_BICEP="$REPO_ROOT/infra/main.bicep"

echo "=== Bicep Build Test ==="
echo "Target: $MAIN_BICEP"
echo

if [ ! -f "$MAIN_BICEP" ]; then
    echo "FAIL: main.bicep not found at $MAIN_BICEP"
    exit 1
fi

echo -n "Building main.bicep... "
if az bicep build --file "$MAIN_BICEP" --stdout > /dev/null 2>&1; then
    echo "OK"
    echo
    echo "Bicep build test PASSED"
    exit 0
else
    echo "FAIL"
    echo
    echo "Build errors:"
    az bicep build --file "$MAIN_BICEP" 2>&1 || true
    echo
    echo "Bicep build test FAILED"
    exit 1
fi
