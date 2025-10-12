#!/usr/bin/env bash
#
# T012: Integration Test - Security Validation
# Test scenario: Verify managed identity, role assignments, no secrets
# Based on quickstart.md Scenario 4
# Expected to FAIL initially (no infrastructure exists yet)
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SECURITY_SCRIPT="$REPO_ROOT/infra/scripts/verify-security.sh"
PARAMS_DIR="$REPO_ROOT/infra/parameters"

echo "=== Integration Test: Security Validation ==="
echo

# Check security validation script exists
if [ ! -f "$SECURITY_SCRIPT" ]; then
    echo "FAIL: Security validation script not found at $SECURITY_SCRIPT"
    exit 1
fi

echo "Security script found: OK"
echo

# Check parameter files don't contain secrets
echo "Checking parameter files for secrets..."
if grep -r "password\|secret\|key\|connectionString" "$PARAMS_DIR" 2>/dev/null | grep -v "param.*:"; then
    echo "WARNING: Found potential secrets in parameter files"
    echo "(Review manually to ensure these are parameter names, not actual secrets)"
else
    echo "No secrets found in parameter files: OK"
fi

echo
echo "Security validation test structure PASSED"
echo "(Actual security validation will be tested in T032)"
exit 0
