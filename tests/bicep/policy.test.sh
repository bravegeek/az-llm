#!/usr/bin/env bash
#
# T007: Azure Policy Compliance Test
# Validates deployment meets security requirements
# Expected to FAIL initially (no templates exist yet)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAIN_BICEP="$REPO_ROOT/infra/main.bicep"

echo "=== Azure Policy Compliance Test ==="
echo

# Check main.bicep exists
if [ ! -f "$MAIN_BICEP" ]; then
    echo "FAIL: main.bicep not found"
    exit 1
fi

echo "Policy checks:"
echo "  1. Checking for TLS 1.2+ requirement... "
if grep -q "minTlsVersion.*1\.2" "$MAIN_BICEP" || \
   grep -q "minTlsVersion.*1\.3" "$MAIN_BICEP" || \
   find "$REPO_ROOT/infra/modules" -name "*.bicep" -exec grep -q "minTlsVersion.*1\.2\|minTlsVersion.*1\.3" {} \; 2>/dev/null; then
    echo "     OK"
else
    echo "     FAIL: TLS 1.2 not enforced"
    exit 1
fi

echo "  2. Checking for managed identity... "
if grep -q "identity.*type.*SystemAssigned" "$MAIN_BICEP" || \
   find "$REPO_ROOT/infra/modules" -name "*.bicep" -exec grep -q "identity.*type.*SystemAssigned" {} \; 2>/dev/null; then
    echo "     OK"
else
    echo "     FAIL: Managed identity not configured"
    exit 1
fi

echo "  3. Checking for HTTPS-only enforcement... "
if grep -q "httpsOnly.*true" "$MAIN_BICEP" || \
   find "$REPO_ROOT/infra/modules" -name "*.bicep" -exec grep -q "httpsOnly.*true" {} \; 2>/dev/null; then
    echo "     OK"
else
    echo "     FAIL: HTTPS-only not enforced"
    exit 1
fi

echo
echo "Policy compliance test PASSED"
exit 0
