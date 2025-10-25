#!/bin/bash
# T031: Test runner orchestrator for AI Foundry deployment tests
# Runs all test suites in sequence with reporting
set -e

echo "========================================="
echo "AI Foundry Hub-less Deployment Test Suite"
echo "========================================="
echo ""

FAILED=0
PASSED=0
SKIPPED=0

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

run_test() {
    local test_file=$1
    local test_name=$2

    echo "========================================="
    echo "Running: $test_name"
    echo "========================================="

    if bash "$test_file"; then
        echo -e "${GREEN}✅ PASSED${NC}: $test_name"
        ((PASSED++))
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 0 ]; then
            echo -e "${YELLOW}⚠️  SKIPPED${NC}: $test_name"
            ((SKIPPED++))
        else
            echo -e "${RED}❌ FAILED${NC}: $test_name"
            ((FAILED++))
        fi
    fi
    echo ""
}

# Phase 1: Static Tests (No deployment required)
echo "=== Phase 1: Static Validation Tests ==="
echo ""

run_test "tests/bicep/linter.test.sh" "Bicep Linter"
run_test "tests/bicep/build.test.sh" "Bicep Build"
run_test "tests/bicep/parameter-validation.test.sh" "Parameter Validation"
run_test "tests/bicep/contract-input.test.sh" "Contract Input Schema"
run_test "tests/bicep/contract-output.test.sh" "Contract Output Schema"

# Phase 2: Integration Tests (Require deployment)
echo "=== Phase 2: Integration Tests (Deployment Required) ==="
echo ""

if [ -n "$RESOURCE_GROUP" ] && [ -n "$AI_SERVICES_NAME" ]; then
    echo "Testing deployment:"
    echo "  Resource Group: $RESOURCE_GROUP"
    echo "  AI Services: $AI_SERVICES_NAME"
    echo ""

    run_test "tests/bicep/quickstart-scenario-1.test.sh" "Scenario 1: Infrastructure Validation"
    run_test "tests/bicep/quickstart-scenario-2.test.sh" "Scenario 2: Model TPM Validation"
    run_test "tests/bicep/quickstart-scenario-3.test.sh" "Scenario 3: Output Format Validation"
    run_test "tests/bicep/quickstart-scenario-4.test.sh" "Scenario 4: Endpoint Connectivity"
    run_test "tests/bicep/quickstart-scenario-5.test.sh" "Scenario 5: Model Availability"
    run_test "tests/bicep/quickstart-scenario-6.test.sh" "Scenario 6: Clean RG Validation"
else
    echo "⚠️  Skipping integration tests (no RESOURCE_GROUP or AI_SERVICES_NAME set)"
    echo "   To run integration tests, export these environment variables:"
    echo "   export RESOURCE_GROUP=<your-rg>"
    echo "   export AI_SERVICES_NAME=<your-ai-services-name>"
    echo ""
    SKIPPED=$((SKIPPED + 6))
fi

# Summary
echo "========================================="
echo "Test Suite Summary"
echo "========================================="
echo -e "${GREEN}Passed:${NC}  $PASSED"
echo -e "${RED}Failed:${NC}  $FAILED"
echo -e "${YELLOW}Skipped:${NC} $SKIPPED"
echo "========================================="
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ $FAILED test(s) failed${NC}"
    exit 1
fi
