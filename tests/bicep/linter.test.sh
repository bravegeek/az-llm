#!/usr/bin/env bash
#
# T004: Bicep Linter Test
# Validates all .bicep files in infra/ pass az bicep lint
# Expected to FAIL initially (no Bicep files exist yet)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
INFRA_DIR="$REPO_ROOT/infra"

echo "=== Bicep Linter Test ==="
echo "Scanning: $INFRA_DIR"
echo

# Find all .bicep files
BICEP_FILES=$(find "$INFRA_DIR" -name "*.bicep" -type f 2>/dev/null || true)

if [ -z "$BICEP_FILES" ]; then
    echo "FAIL: No Bicep files found in $INFRA_DIR"
    echo "Expected files: main.bicep, modules/*.bicep"
    exit 1
fi

# Lint each file
FAILED=0
for file in $BICEP_FILES; do
    echo -n "Linting $(basename "$file")... "
    if az bicep lint --file "$file" 2>&1 | grep -q "Error\|error"; then
        echo "FAIL"
        az bicep lint --file "$file" 2>&1 || true
        FAILED=1
    else
        echo "OK"
    fi
done

if [ $FAILED -eq 1 ]; then
    echo
    echo "Bicep linter test FAILED"
    exit 1
fi

echo
echo "Bicep linter test PASSED"
exit 0
