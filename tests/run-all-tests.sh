#!/usr/bin/env bash
#
# T024: Test Runner Script
# Runs all infrastructure validation tests in sequence
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== Azure Infrastructure Test Suite ==="
echo

FAILED_TESTS=()
PASSED_TESTS=()

run_test() {
    local test_name="$1"
    local test_script="$2"

    echo -n "Running $test_name... "
    if "$test_script" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS+=("$test_name")
        return 0
    else
        echo -e "${RED}FAIL${NC}"
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

# Bicep Tests
echo "Bicep Validation Tests:"
run_test "Linter" "$SCRIPT_DIR/bicep/linter.test.sh" || true
run_test "Build" "$SCRIPT_DIR/bicep/build.test.sh" || true
run_test "Parameter Validation" "$SCRIPT_DIR/bicep/parameter-validation.test.sh" || true
run_test "Policy Compliance" "$SCRIPT_DIR/bicep/policy.test.sh" || true
run_test "Deployment Validation" "$SCRIPT_DIR/bicep/deployment.test.sh" || true

echo

# Integration Tests
echo "Integration Tests:"
run_test "Fresh Deployment" "$SCRIPT_DIR/integration/fresh-deployment.test.sh" || true
run_test "Update Deployment" "$SCRIPT_DIR/integration/update-deployment.test.sh" || true
run_test "Multi-Environment" "$SCRIPT_DIR/integration/multi-environment.test.sh" || true
run_test "Security Validation" "$SCRIPT_DIR/integration/security-validation.test.sh" || true

echo
echo "=== Test Results ==="
echo "Passed: ${#PASSED_TESTS[@]}"
echo "Failed: ${#FAILED_TESTS[@]}"

if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    echo
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo
    echo -e "${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  - $test"
    done
    exit 1
fi
