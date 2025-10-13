#!/bin/bash
# T021: Pre-deployment validation script
set -e

echo "🔍 Validating Bicep infrastructure..."
echo ""

# Run linter test
echo "1/3 Running Bicep syntax validation..."
./tests/bicep/linter.test.sh

# Run build test
echo "2/3 Running Bicep build validation..."
./tests/bicep/build.test.sh

# Run parameter validation
echo "3/3 Running parameter validation..."
./tests/bicep/parameter-validation.test.sh

echo ""
echo "✅ All validation checks passed!"
echo "💡 Ready for deployment. Run: ./scripts/deploy.sh <resource-group> @infra/main.parameters.json"
