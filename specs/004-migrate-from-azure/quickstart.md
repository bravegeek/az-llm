# Quickstart: Azure AI Foundry Migration

**Feature**: 004-migrate-from-azure
**Date**: 2025-10-19
**Version**: 1.0.0

## Overview

This quickstart guide validates the Azure AI Foundry infrastructure deployment through 6 integration test scenarios. Each scenario tests a specific aspect of the migration from Azure OpenAI to AI Foundry.

## Prerequisites

- Azure CLI 2.50+ installed and authenticated
- Bicep CLI installed
- jq (JSON processor) installed
- Bash 4.0+
- Valid Azure subscription with quota for:
  - AI Foundry Hub (ML Workspace)
  - AI Foundry Project (ML Workspace)
  - AI Services account
  - 5 model deployments (260 TPM total)

## Test Scenarios

### Scenario 1: Deploy Fresh AI Foundry Infrastructure

**Objective**: Validate end-to-end deployment of Hub + Project + AI Services + 5 models

**Steps**:
1. Set deployment parameters in `infra/main.parameters.json`:
   ```json
   {
     "location": { "value": "eastus2" },
     "hubName": { "value": "test-hub-001" },
     "projectName": { "value": "test-project-001" },
     "aiServicesName": { "value": "test-ai-001" }
   }
   ```

2. Run validation:
   ```bash
   ./scripts/validate.sh
   ```

3. Deploy infrastructure:
   ```bash
   ./scripts/deploy.sh
   ```

4. Verify deployment success:
   ```bash
   az deployment group show \
     --name main \
     --resource-group rg-ai-foundry \
     --query "properties.provisioningState"
   ```

**Expected Output**:
- Deployment completes in <10 minutes
- Provisioning state: "Succeeded"
- All 5 model deployments created
- No errors in deployment logs

**Validation**:
```bash
# Verify Hub exists
az ml workspace show --name test-hub-001 --resource-group rg-ai-foundry

# Verify Project exists
az ml workspace show --name test-project-001 --resource-group rg-ai-foundry

# Verify AI Services exists
az cognitiveservices account show --name test-ai-001 --resource-group rg-ai-foundry

# Count deployments
az cognitiveservices account deployment list \
  --name test-ai-001 \
  --resource-group rg-ai-foundry \
  --query "length(@)"
# Expected: 5
```

**Success Criteria**:
- ✅ Deployment state = "Succeeded"
- ✅ Hub kind = "Hub"
- ✅ Project kind = "Project" and hubResourceId matches Hub
- ✅ AI Services kind = "AIServices"
- ✅ Exactly 5 deployments exist

---

### Scenario 2: Validate All 5 Models Deployed with Correct TPM

**Objective**: Verify each model deployment has correct name, version, and TPM capacity

**Steps**:
1. List all deployments:
   ```bash
   az cognitiveservices account deployment list \
     --name test-ai-001 \
     --resource-group rg-ai-foundry \
     --output json > deployments.json
   ```

2. Validate each deployment:
   ```bash
   jq -r '.[] | "\(.name): \(.properties.model.name) v\(.properties.model.version) (\(.sku.capacity) TPM)"' deployments.json
   ```

3. Verify total capacity:
   ```bash
   jq '[.[] | .sku.capacity] | add' deployments.json
   ```

**Expected Output**:
```
gpt-41-deployment: gpt-4.1 v2025-04-14 (50 TPM)
gpt-41-mini-deployment: gpt-4o-mini v2024-07-18 (100 TPM)
gpt-4o-deployment: gpt-4o v2024-08-06 (50 TPM)
flux-deployment: FLUX-1.1-pro vlatest (10 TPM)
deepseek-deployment: DeepSeek-V3.1 vlatest (50 TPM)
Total: 260 TPM
```

**Validation Script**:
```bash
#!/bin/bash
EXPECTED=(
  "gpt-41-deployment:gpt-4.1:2025-04-14:50"
  "gpt-41-mini-deployment:gpt-4o-mini:2024-07-18:100"
  "gpt-4o-deployment:gpt-4o:2024-08-06:50"
  "flux-deployment:FLUX-1.1-pro:latest:10"
  "deepseek-deployment:DeepSeek-V3.1:latest:50"
)

DEPLOYMENTS=$(az cognitiveservices account deployment list \
  --name test-ai-001 \
  --resource-group rg-ai-foundry \
  --output json)

for expected in "${EXPECTED[@]}"; do
  IFS=':' read -r name model version capacity <<< "$expected"
  FOUND=$(echo "$DEPLOYMENTS" | jq -r \
    ".[] | select(.name==\"$name\" and .properties.model.name==\"$model\" and .properties.model.version==\"$version\" and .sku.capacity==$capacity) | .name")

  if [[ "$FOUND" == "$name" ]]; then
    echo "✅ $name validated"
  else
    echo "❌ $name mismatch or missing"
    exit 1
  fi
done

TOTAL=$(echo "$DEPLOYMENTS" | jq '[.[] | .sku.capacity] | add')
if [[ "$TOTAL" == "260" ]]; then
  echo "✅ Total TPM capacity: 260"
else
  echo "❌ Total TPM capacity: $TOTAL (expected 260)"
  exit 1
fi
```

**Success Criteria**:
- ✅ All 5 deployments match expected configuration
- ✅ Total TPM = 260

---

### Scenario 3: Extract Outputs to .env Format

**Objective**: Verify deployment outputs can be transformed to .env.azure-openai format

**Steps**:
1. Extract deployment outputs:
   ```bash
   ./scripts/outputs.sh
   ```

2. Verify .env.azure-openai file created:
   ```bash
   cat .env.azure-openai
   ```

3. Validate output schema:
   ```bash
   az deployment group show \
     --name main \
     --resource-group rg-ai-foundry \
     --query "properties.outputs" > outputs.json

   ajv validate \
     -s specs/004-migrate-from-azure/contracts/output-schema.json \
     -d outputs.json
   ```

**Expected .env.azure-openai Format**:
```bash
AZURE_OPENAI_ENDPOINT=https://test-ai-001.eastus2.inference.ml.azure.com/
AZURE_OPENAI_KEY=********************************
AZURE_OPENAI_DEPLOYMENT_GPT41=gpt-41-deployment
AZURE_OPENAI_DEPLOYMENT_GPT41_MINI=gpt-41-mini-deployment
AZURE_OPENAI_DEPLOYMENT_GPT4O=gpt-4o-deployment
AZURE_OPENAI_DEPLOYMENT_FLUX=flux-deployment
AZURE_OPENAI_DEPLOYMENT_DEEPSEEK=deepseek-deployment
```

**Validation**:
```bash
#!/bin/bash
source .env.azure-openai

# Verify all variables set
REQUIRED_VARS=(
  "AZURE_OPENAI_ENDPOINT"
  "AZURE_OPENAI_KEY"
  "AZURE_OPENAI_DEPLOYMENT_GPT41"
  "AZURE_OPENAI_DEPLOYMENT_GPT41_MINI"
  "AZURE_OPENAI_DEPLOYMENT_GPT4O"
  "AZURE_OPENAI_DEPLOYMENT_FLUX"
  "AZURE_OPENAI_DEPLOYMENT_DEEPSEEK"
)

for var in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!var}" ]]; then
    echo "❌ Missing: $var"
    exit 1
  fi
  echo "✅ $var set"
done

# Verify endpoint format
if [[ ! "$AZURE_OPENAI_ENDPOINT" =~ ^https://[a-z0-9-]+\.[a-z0-9]+\.inference\.ml\.azure\.com/$ ]]; then
  echo "❌ Invalid endpoint format"
  exit 1
fi
echo "✅ Endpoint format valid"
```

**Success Criteria**:
- ✅ .env.azure-openai file created
- ✅ All 7 environment variables present
- ✅ Endpoint format matches AI Foundry pattern
- ✅ Outputs pass JSON Schema validation

---

### Scenario 4: Test Model Endpoint Connectivity

**Objective**: Verify each model deployment responds to API calls

**Steps**:
1. Source environment variables:
   ```bash
   source .env.azure-openai
   ```

2. Test each model endpoint:
   ```bash
   for deployment in \
     "$AZURE_OPENAI_DEPLOYMENT_GPT41" \
     "$AZURE_OPENAI_DEPLOYMENT_GPT41_MINI" \
     "$AZURE_OPENAI_DEPLOYMENT_GPT4O" \
     "$AZURE_OPENAI_DEPLOYMENT_FLUX" \
     "$AZURE_OPENAI_DEPLOYMENT_DEEPSEEK"
   do
     echo "Testing $deployment..."
     curl -s -X POST \
       "${AZURE_OPENAI_ENDPOINT}openai/deployments/${deployment}/chat/completions?api-version=2024-02-15-preview" \
       -H "Content-Type: application/json" \
       -H "api-key: $AZURE_OPENAI_KEY" \
       -d '{
         "messages": [{"role": "user", "content": "Hello"}],
         "max_tokens": 10
       }' | jq -r '.choices[0].message.content // "ERROR"'
   done
   ```

**Expected Output**:
```
Testing gpt-41-deployment...
Hello! How can I help...

Testing gpt-41-mini-deployment...
Hi there! What can I...

Testing gpt-4o-deployment...
Hello! How may I assist...

Testing flux-deployment...
[Image generation response or appropriate model response]

Testing deepseek-deployment...
Hello! I'm ready to help...
```

**Validation Script**:
```bash
#!/bin/bash
source .env.azure-openai

DEPLOYMENTS=(
  "$AZURE_OPENAI_DEPLOYMENT_GPT41"
  "$AZURE_OPENAI_DEPLOYMENT_GPT41_MINI"
  "$AZURE_OPENAI_DEPLOYMENT_GPT4O"
  "$AZURE_OPENAI_DEPLOYMENT_FLUX"
  "$AZURE_OPENAI_DEPLOYMENT_DEEPSEEK"
)

SUCCESS=0
FAILED=0

for deployment in "${DEPLOYMENTS[@]}"; do
  RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "${AZURE_OPENAI_ENDPOINT}openai/deployments/${deployment}/chat/completions?api-version=2024-02-15-preview" \
    -H "Content-Type: application/json" \
    -H "api-key: $AZURE_OPENAI_KEY" \
    -d '{"messages":[{"role":"user","content":"test"}],"max_tokens":5}')

  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  BODY=$(echo "$RESPONSE" | head -n-1)

  if [[ "$HTTP_CODE" == "200" ]]; then
    echo "✅ $deployment: Connected (HTTP $HTTP_CODE)"
    ((SUCCESS++))
  else
    echo "❌ $deployment: Failed (HTTP $HTTP_CODE)"
    echo "$BODY" | jq '.'
    ((FAILED++))
  fi
done

echo "Results: $SUCCESS succeeded, $FAILED failed"
[[ $FAILED -eq 0 ]] && exit 0 || exit 1
```

**Success Criteria**:
- ✅ All 5 models return HTTP 200
- ✅ All responses contain valid content
- ✅ No authentication errors
- ✅ Response time <2 seconds per model

---

### Scenario 5: Validate Region-Specific Model Availability

**Objective**: Verify pre-deployment validation catches unavailable models in target region

**Steps**:
1. Update parameters to use unsupported region:
   ```json
   {
     "location": { "value": "brazilsouth" }
   }
   ```

2. Run validation:
   ```bash
   ./scripts/validate.sh
   ```

**Expected Output**:
```
❌ Validation failed: Model 'FLUX-1.1-pro' not available in region 'brazilsouth'
Available regions for FLUX-1.1-pro: eastus, eastus2, westus, northcentralus

Deployment aborted.
```

**Validation Logic** (in validate.sh):
```bash
#!/bin/bash
LOCATION="$1"
MODELS=("gpt-4.1" "gpt-4o-mini" "gpt-4o" "FLUX-1.1-pro" "DeepSeek-V3.1")

for model in "${MODELS[@]}"; do
  AVAILABLE=$(az cognitiveservices model list \
    --location "$LOCATION" \
    --query "[?name=='$model'].name" -o tsv)

  if [[ -z "$AVAILABLE" ]]; then
    echo "❌ Model '$model' not available in region '$LOCATION'"

    # Show available regions
    REGIONS=$(az cognitiveservices model list \
      --query "[?name=='$model'].location[]" -o tsv | sort -u | tr '\n' ', ')
    echo "Available regions for $model: ${REGIONS%,}"

    exit 1
  fi
  echo "✅ Model '$model' available in '$LOCATION'"
done

echo "✅ All models available in region '$LOCATION'"
```

**Success Criteria**:
- ✅ Validation detects unavailable models
- ✅ Error message lists available regions
- ✅ Deployment does not proceed
- ✅ Exit code = 1

---

### Scenario 6: Deploy with Invalid Region (Expect Failure)

**Objective**: Verify deployment fails gracefully with clear error for unsupported region

**Steps**:
1. Set invalid location:
   ```json
   {
     "location": { "value": "invalidregion" }
   }
   ```

2. Attempt deployment:
   ```bash
   ./scripts/deploy.sh 2>&1 | tee deployment.log
   ```

**Expected Output**:
```
❌ Deployment failed: Location 'invalidregion' is not a valid Azure region
Valid regions: eastus, eastus2, westus, westus3, northcentralus, ...

Rollback: No resources created.
```

**Validation**:
```bash
#!/bin/bash
# Verify deployment failed
az deployment group show \
  --name main \
  --resource-group rg-ai-foundry \
  --query "properties.provisioningState" -o tsv

# Expected: "Failed" or deployment not found

# Verify no resources created
RESOURCES=$(az resource list \
  --resource-group rg-ai-foundry \
  --query "length(@)" -o tsv)

if [[ "$RESOURCES" == "0" ]]; then
  echo "✅ No resources created (correct rollback)"
else
  echo "❌ $RESOURCES resources found (incomplete rollback)"
  exit 1
fi
```

**Success Criteria**:
- ✅ Deployment fails fast (no partial creation)
- ✅ Clear error message identifying invalid region
- ✅ No orphaned resources
- ✅ Exit code = 1

---

## Running All Scenarios

### Automated Test Suite

```bash
#!/bin/bash
# tests/bicep/quickstart-all.sh

SCENARIOS=(
  "quickstart-scenario-1.test.sh"
  "quickstart-scenario-2.test.sh"
  "quickstart-scenario-3.test.sh"
  "quickstart-scenario-4.test.sh"
  "quickstart-scenario-5.test.sh"
  "quickstart-scenario-6.test.sh"
)

PASSED=0
FAILED=0

for scenario in "${SCENARIOS[@]}"; do
  echo "========================================="
  echo "Running: $scenario"
  echo "========================================="

  if bash "tests/bicep/$scenario"; then
    echo "✅ $scenario PASSED"
    ((PASSED++))
  else
    echo "❌ $scenario FAILED"
    ((FAILED++))
  fi
  echo ""
done

echo "========================================="
echo "Results: $PASSED passed, $FAILED failed"
echo "========================================="

[[ $FAILED -eq 0 ]] && exit 0 || exit 1
```

### CI/CD Integration

```yaml
# .github/workflows/ai-foundry-test.yml
name: AI Foundry Quickstart Tests

on:
  push:
    paths:
      - 'infra/**'
      - 'scripts/**'
      - 'tests/bicep/**'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Run Quickstart Scenarios
        run: |
          chmod +x tests/bicep/quickstart-all.sh
          ./tests/bicep/quickstart-all.sh

      - name: Cleanup Resources
        if: always()
        run: |
          az group delete --name rg-ai-foundry --yes --no-wait
```

---

## Cleanup

After running scenarios, clean up test resources:

```bash
# Delete resource group
az group delete --name rg-ai-foundry --yes

# Verify deletion
az group exists --name rg-ai-foundry
# Expected: false
```

---

## Success Summary

| Scenario | Focus | Expected Duration |
|----------|-------|-------------------|
| 1 | End-to-end deployment | 8-10 minutes |
| 2 | Model configuration validation | 30 seconds |
| 3 | Output format compatibility | 15 seconds |
| 4 | Endpoint connectivity | 1 minute |
| 5 | Pre-deployment validation | 30 seconds |
| 6 | Error handling | 1 minute |

**Total Test Time**: ~12-15 minutes

**Coverage**:
- ✅ Infrastructure provisioning
- ✅ Resource hierarchy (Hub → Project → AI Services → Deployments)
- ✅ Model deployment configuration
- ✅ TPM capacity allocation
- ✅ Output schema compliance
- ✅ Client compatibility (.env format)
- ✅ API connectivity
- ✅ Pre-deployment validation
- ✅ Error handling and rollback

---

**Status**: Ready for implementation
**Next**: Update CLAUDE.md agent context
