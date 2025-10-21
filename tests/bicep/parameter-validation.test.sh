#!/bin/bash
# T008: Parameter validation test
set -e

echo "=== Parameter validation test ==="

# Validate parameters file is valid JSON
if ! jq empty infra/main.parameters.json 2>/dev/null; then
    echo "❌ Parameters file is not valid JSON"
    exit 1
fi

# Validate required parameters exist
REQUIRED_PARAMS=("location" "aiServicesName" "customSubDomain" "projectName")
for param in "${REQUIRED_PARAMS[@]}"; do
  VALUE=$(jq -r ".parameters.$param.value // empty" infra/main.parameters.json)
  if [ -z "$VALUE" ]; then
    echo "❌ Missing required parameter: $param"
    exit 1
  fi
  echo "✅ Parameter $param: $VALUE"
done

echo "✅ All required parameters valid"
exit 0
