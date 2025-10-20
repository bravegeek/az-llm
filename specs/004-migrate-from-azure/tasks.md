# Tasks: Migrate to Azure AI Foundry

**Feature**: 004-migrate-from-azure
**Input**: Design documents from `/home/greg/dev/az-llm/specs/004-migrate-from-azure/`
**Prerequisites**: plan.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → Extract: Bicep, Bash, Azure CLI tech stack
   → Structure: Single project (infrastructure)
2. Load design documents:
   → data-model.md: 6 entities (Hub, Project, AI Services, Deployments, Parameters, Outputs)
   → contracts/: 2 files (input-schema.json, output-schema.json)
   → quickstart.md: 6 integration scenarios
3. Generate tasks by category:
   → Setup: Archive old infra, update parameters
   → Tests: 2 contract tests, 6 quickstart tests
   → Core: Single Bicep file implementation
   → Integration: 3 script updates
   → Polish: Documentation, validation
4. Apply TDD ordering:
   → Tests before implementation (Phase 3.2 before 3.3)
   → Different files = [P] for parallel
   → Models before services before endpoints
5. Number tasks: T001-T024 (24 tasks total)
6. SUCCESS: Tasks ready for execution
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Phase 3.1: Setup & Preparation

### T001 - Archive Current Azure OpenAI Infrastructure
**Files**: `infra/main.bicep`, `infra/main.parameters.json`
**Action**: Move existing Azure OpenAI infrastructure to archive directory
**Details**:
```bash
# Create archive directory
mkdir -p infra-archive/2025-10-19-azure-openai
# Move current files
cp infra/main.bicep infra-archive/2025-10-19-azure-openai/
cp infra/main.parameters.json infra-archive/2025-10-19-azure-openai/
# Verify archive
ls -la infra-archive/2025-10-19-azure-openai/
```
**Dependencies**: None
**Completion Criteria**: Old Bicep files archived with timestamp

---

### T002 - Update Parameters File for AI Foundry
**Files**: `infra/main.parameters.json`
**Action**: Create new parameters file with 19 parameters for Hub, Project, AI Services, and 5 models
**Details**:
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": { "value": "eastus2" },
    "hubName": { "value": "bg-llm-hub" },
    "projectName": { "value": "bg-llm-project" },
    "aiServicesName": { "value": "bg-llm-ai" },
    "gpt41ModelName": { "value": "gpt-4.1" },
    "gpt41ModelVersion": { "value": "2025-04-14" },
    "gpt41CapacityTPM": { "value": 50 },
    "gpt41MiniModelName": { "value": "gpt-4o-mini" },
    "gpt41MiniModelVersion": { "value": "2024-07-18" },
    "gpt41MiniCapacityTPM": { "value": 100 },
    "gpt4oModelName": { "value": "gpt-4o" },
    "gpt4oModelVersion": { "value": "2024-08-06" },
    "gpt4oCapacityTPM": { "value": 50 },
    "fluxModelName": { "value": "FLUX-1.1-pro" },
    "fluxModelVersion": { "value": "latest" },
    "fluxCapacityTPM": { "value": 10 },
    "deepseekModelName": { "value": "DeepSeek-V3.1" },
    "deepseekModelVersion": { "value": "latest" },
    "deepseekCapacityTPM": { "value": 50 }
  }
}
```
**Dependencies**: T001
**Completion Criteria**: Parameters file matches input-schema.json

---

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### T003 [P] - Contract Test for Input Schema
**Files**: `tests/bicep/contract-input.test.sh`
**Action**: Update contract test to validate AI Foundry input parameters against JSON Schema
**Details**:
```bash
#!/bin/bash
set -e

echo "=== Testing input contract schema ==="

# Validate parameters file against schema
ajv validate \
  -s specs/004-migrate-from-azure/contracts/input-schema.json \
  -d infra/main.parameters.json

if [ $? -eq 0 ]; then
  echo "✅ Input parameters valid"
  exit 0
else
  echo "❌ Input parameters validation failed"
  exit 1
fi
```
**Dependencies**: T002
**Completion Criteria**: Test exists and FAILS (no Bicep implementation yet)

---

### T004 [P] - Contract Test for Output Schema
**Files**: `tests/bicep/contract-output.test.sh`
**Action**: Update contract test to validate AI Foundry outputs against JSON Schema
**Details**:
```bash
#!/bin/bash
set -e

echo "=== Testing output contract schema ==="

# Build Bicep to get outputs structure
az bicep build --file infra/main.bicep --outfile /tmp/main.json

# Extract outputs schema
jq '.outputs' /tmp/main.json > /tmp/outputs-structure.json

# Validate against output schema
ajv validate \
  -s specs/004-migrate-from-azure/contracts/output-schema.json \
  -d /tmp/outputs-structure.json

if [ $? -eq 0 ]; then
  echo "✅ Output schema valid"
  exit 0
else
  echo "❌ Output schema validation failed"
  exit 1
fi
```
**Dependencies**: None (parallel with T003)
**Completion Criteria**: Test exists and FAILS (no Bicep implementation yet)

---

### T005 [P] - Update Linter Test for AI Foundry Resources
**Files**: `tests/bicep/linter.test.sh`
**Action**: Update linter test to expect AI Foundry resource types
**Details**:
```bash
#!/bin/bash
set -e

echo "=== Bicep linter test ==="

# Run Bicep linter
az bicep lint --file infra/main.bicep

if [ $? -eq 0 ]; then
  echo "✅ Bicep linter passed"
  exit 0
else
  echo "❌ Bicep linter failed"
  exit 1
fi
```
**Dependencies**: None (parallel with T003, T004)
**Completion Criteria**: Test exists (will fail until Bicep updated)

---

### T006 [P] - Update Build Test for AI Foundry
**Files**: `tests/bicep/build.test.sh`
**Action**: Update build test to compile AI Foundry Bicep to ARM
**Details**:
```bash
#!/bin/bash
set -e

echo "=== Bicep build test ==="

# Build Bicep to ARM template
az bicep build --file infra/main.bicep --outfile /tmp/main.json

# Verify output exists and is valid JSON
if [ -f /tmp/main.json ] && jq empty /tmp/main.json 2>/dev/null; then
  echo "✅ Bicep build succeeded"
  exit 0
else
  echo "❌ Bicep build failed"
  exit 1
fi
```
**Dependencies**: None (parallel with T003-T005)
**Completion Criteria**: Test exists (will fail until Bicep updated)

---

### T007 [P] - Update Parameter Validation Test
**Files**: `tests/bicep/parameter-validation.test.sh`
**Action**: Update test to validate 19 AI Foundry parameters
**Details**:
```bash
#!/bin/bash
set -e

echo "=== Parameter validation test ==="

# Validate parameters file is valid JSON
jq empty infra/main.parameters.json

# Validate required parameters exist
REQUIRED_PARAMS=("location" "hubName" "projectName" "aiServicesName")
for param in "${REQUIRED_PARAMS[@]}"; do
  VALUE=$(jq -r ".parameters.$param.value" infra/main.parameters.json)
  if [ "$VALUE" == "null" ] || [ -z "$VALUE" ]; then
    echo "❌ Missing required parameter: $param"
    exit 1
  fi
  echo "✅ Parameter $param: $VALUE"
done

echo "✅ All required parameters valid"
exit 0
```
**Dependencies**: T002
**Completion Criteria**: Test passes with new parameters file

---

### T008 [P] - Quickstart Scenario 1 Test (End-to-End Deployment)
**Files**: `tests/bicep/quickstart-scenario-1.test.sh`
**Action**: Update test for AI Foundry Hub + Project + AI Services + 5 models deployment
**Details**: See quickstart.md Scenario 1 - validates full deployment flow
**Dependencies**: None (parallel with T003-T007)
**Completion Criteria**: Test exists and FAILS (no infrastructure deployed)

---

### T009 [P] - Quickstart Scenario 2 Test (Model TPM Validation)
**Files**: `tests/bicep/quickstart-scenario-2.test.sh`
**Action**: Update test to validate all 5 models with correct TPM allocations (260 total)
**Details**: See quickstart.md Scenario 2 - validates model configurations
**Dependencies**: None (parallel with T003-T008)
**Completion Criteria**: Test exists and FAILS (no deployments exist)

---

### T010 [P] - Quickstart Scenario 3 Test (Output Format)
**Files**: `tests/bicep/quickstart-scenario-3.test.sh`
**Action**: Update test to validate .env.azure-openai output format
**Details**: See quickstart.md Scenario 3 - validates output extraction
**Dependencies**: None (parallel with T003-T009)
**Completion Criteria**: Test exists and FAILS (no outputs generated)

---

### T011 [P] - Quickstart Scenario 4 Test (Endpoint Connectivity)
**Files**: `tests/bicep/quickstart-scenario-4.test.sh`
**Action**: Update test to validate all 5 model endpoints respond to API calls
**Details**: See quickstart.md Scenario 4 - validates model connectivity
**Dependencies**: None (parallel with T003-T010)
**Completion Criteria**: Test exists and FAILS (no endpoints available)

---

### T012 [P] - Quickstart Scenario 5 Test (Region Validation)
**Files**: `tests/bicep/quickstart-scenario-5.test.sh`
**Action**: Update test to validate region-specific model availability check
**Details**: See quickstart.md Scenario 5 - validates pre-deployment checks
**Dependencies**: None (parallel with T003-T011)
**Completion Criteria**: Test exists (validation logic independent of deployment)

---

### T013 [P] - Quickstart Scenario 6 Test (Invalid Region Handling)
**Files**: `tests/bicep/quickstart-scenario-6.test.sh`
**Action**: Update test to validate graceful failure with invalid region
**Details**: See quickstart.md Scenario 6 - validates error handling
**Dependencies**: None (parallel with T003-T012)
**Completion Criteria**: Test exists (error handling logic)

---

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### T014 - Implement AI Foundry Hub in Bicep
**Files**: `infra/main.bicep`
**Action**: Add Hub resource (Microsoft.MachineLearningServices/workspaces kind='Hub')
**Details**:
```bicep
// Hub resource
resource hub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: hubName
  location: location
  kind: 'Hub'
  sku: {
    name: 'Basic'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: hubName
    description: 'Azure AI Foundry Hub for LLM deployments'
  }
}
```
**Dependencies**: T003-T013 (all tests must exist and fail first)
**Completion Criteria**: Hub resource compiles, linter passes

---

### T015 - Implement AI Foundry Project in Bicep
**Files**: `infra/main.bicep`
**Action**: Add Project resource (Microsoft.MachineLearningServices/workspaces kind='Project')
**Details**:
```bicep
// Project resource
resource project 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: projectName
  location: location
  kind: 'Project'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: projectName
    description: 'AI Foundry Project for model deployments'
    hubResourceId: hub.id
  }
  dependsOn: [hub]
}
```
**Dependencies**: T014
**Completion Criteria**: Project resource compiles, references Hub correctly

---

### T016 - Implement AI Services Resource in Bicep
**Files**: `infra/main.bicep`
**Action**: Add AI Services account (Microsoft.CognitiveServices/accounts kind='AIServices')
**Details**:
```bicep
// AI Services resource
resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServicesName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: aiServicesName
  }
}
```
**Dependencies**: T015
**Completion Criteria**: AI Services resource compiles independently

---

### T017 - Implement 5 Model Deployments in Bicep
**Files**: `infra/main.bicep`
**Action**: Add 5 model deployments as child resources of AI Services
**Details**:
```bicep
// Model deployments (5 total)
resource gpt41Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: aiServices
  name: 'gpt-41-deployment'
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt41ModelName
      version: gpt41ModelVersion
    }
  }
  sku: {
    name: 'Standard'
    capacity: gpt41CapacityTPM
  }
}

// Repeat for gpt41Mini, gpt4o, flux, deepseek...
```
**Dependencies**: T016
**Completion Criteria**: All 5 deployments compile, total TPM = 260

---

### T018 - Implement Bicep Outputs
**Files**: `infra/main.bicep`
**Action**: Add outputs matching output-schema.json (hub ID, project ID, endpoints, keys, deployments)
**Details**:
```bicep
output hubResourceId string = hub.id
output projectResourceId string = project.id
output aiServicesEndpoint string = 'https://${aiServices.name}.${location}.inference.ml.azure.com/'
output aiServicesKey string = aiServices.listKeys().key1
output gpt41Deployment object = {
  name: gpt41Deployment.name
  model: gpt41ModelName
  version: gpt41ModelVersion
  capacity: gpt41CapacityTPM
}
// Repeat for other 4 models...
```
**Dependencies**: T017
**Completion Criteria**: Outputs match output-schema.json, contract test T004 passes

---

## Phase 3.4: Integration (Scripts & Automation)

### T019 [P] - Update validate.sh for Region/Model Validation
**Files**: `scripts/validate.sh`
**Action**: Add region-specific model availability check before deployment
**Details**:
```bash
#!/bin/bash
set -e

LOCATION=$(jq -r '.parameters.location.value' infra/main.parameters.json)
MODELS=("gpt-4.1" "gpt-4o-mini" "gpt-4o" "FLUX-1.1-pro" "DeepSeek-V3.1")

echo "=== Validating model availability in $LOCATION ==="

for model in "${MODELS[@]}"; do
  echo "Checking $model..."
  # Add Azure CLI check for model availability
done

echo "✅ All models available in $LOCATION"
```
**Dependencies**: T018 (Bicep complete)
**Completion Criteria**: Quickstart scenario 5 test passes

---

### T020 [P] - Update deploy.sh for AI Foundry
**Files**: `scripts/deploy.sh`
**Action**: Minimal updates for AI Foundry resource types (if needed)
**Details**: Verify deploy.sh works with new Bicep template, adjust resource group logic if needed
**Dependencies**: T018 (Bicep complete)
**Completion Criteria**: Deployment succeeds, quickstart scenario 1 test passes

---

### T021 [P] - Update outputs.sh for AI Foundry Format
**Files**: `scripts/outputs.sh`
**Action**: Extract AI Foundry outputs and map to .env.azure-openai format
**Details**:
```bash
#!/bin/bash
set -e

OUTPUTS=$(az deployment group show \
  --name main \
  --resource-group rg-ai-foundry \
  --query "properties.outputs" -o json)

# Extract and format to .env
echo "AZURE_OPENAI_ENDPOINT=$(echo $OUTPUTS | jq -r '.aiServicesEndpoint.value')" > .env.azure-openai
echo "AZURE_OPENAI_KEY=$(echo $OUTPUTS | jq -r '.aiServicesKey.value')" >> .env.azure-openai
echo "AZURE_OPENAI_DEPLOYMENT_GPT41=$(echo $OUTPUTS | jq -r '.gpt41Deployment.value.name')" >> .env.azure-openai
# Continue for all 5 models...
```
**Dependencies**: T018 (Bicep complete)
**Completion Criteria**: Quickstart scenario 3 test passes

---

## Phase 3.5: Polish & Documentation

### T022 - Update infra/README.md
**Files**: `infra/README.md`
**Action**: Update documentation for AI Foundry deployment instructions
**Details**:
- Replace OpenAI references with AI Foundry
- Document Hub → Project → AI Services → Deployments hierarchy
- Update deployment command examples
- Add migration instructions from Azure OpenAI
**Dependencies**: T019-T021
**Completion Criteria**: README accurately reflects AI Foundry infrastructure

---

### T023 - Run Full Test Suite Validation
**Files**: All test files
**Action**: Execute all tests to verify complete implementation
**Details**:
```bash
# Run all tests
./tests/bicep/linter.test.sh
./tests/bicep/build.test.sh
./tests/bicep/parameter-validation.test.sh
./tests/bicep/contract-input.test.sh
./tests/bicep/contract-output.test.sh
./tests/bicep/quickstart-scenario-1.test.sh
./tests/bicep/quickstart-scenario-2.test.sh
./tests/bicep/quickstart-scenario-3.test.sh
./tests/bicep/quickstart-scenario-4.test.sh
./tests/bicep/quickstart-scenario-5.test.sh
./tests/bicep/quickstart-scenario-6.test.sh
```
**Dependencies**: T022
**Completion Criteria**: All tests pass (11 tests total)

---

### T024 - Verify Bicep Line Count < 300
**Files**: `infra/main.bicep`
**Action**: Verify single-file Bicep complexity constraint met
**Details**:
```bash
wc -l infra/main.bicep
# Expected: < 300 lines (simplicity-first principle)
```
**Dependencies**: T023
**Completion Criteria**: Line count < 300, constitutional compliance verified

---

## Dependencies Visualization

```
Setup Phase:
T001 (Archive) → T002 (Parameters)

Test Phase (ALL PARALLEL):
T002 → T003 [P] Contract Input Test
        T004 [P] Contract Output Test
        T005 [P] Linter Test
        T006 [P] Build Test
        T007 [P] Parameter Validation Test
        T008 [P] Quickstart 1 Test
        T009 [P] Quickstart 2 Test
        T010 [P] Quickstart 3 Test
        T011 [P] Quickstart 4 Test
        T012 [P] Quickstart 5 Test
        T013 [P] Quickstart 6 Test

Implementation Phase (SEQUENTIAL):
T003-T013 → T014 (Hub) → T015 (Project) → T016 (AI Services) → T017 (Deployments) → T018 (Outputs)

Integration Phase (ALL PARALLEL after T018):
T018 → T019 [P] Update validate.sh
        T020 [P] Update deploy.sh
        T021 [P] Update outputs.sh

Polish Phase (SEQUENTIAL):
T019-T021 → T022 (Docs) → T023 (Full Test Suite) → T024 (Line Count Check)
```

## Parallel Execution Example

### Batch 1: All Test Creation (After T002)
```bash
# Launch T003-T013 together (11 tests in parallel):
# - 2 contract tests
# - 4 basic validation tests
# - 6 quickstart scenario tests
```

### Batch 2: Script Updates (After T018)
```bash
# Launch T019-T021 together (3 scripts in parallel):
Task: "Update validate.sh for region/model validation in scripts/validate.sh"
Task: "Update deploy.sh for AI Foundry in scripts/deploy.sh"
Task: "Update outputs.sh for AI Foundry format in scripts/outputs.sh"
```

## Task Summary

**Total Tasks**: 24
**Parallel Tasks**: 14 (marked with [P])
**Sequential Tasks**: 10

**By Phase**:
- Setup: 2 tasks
- Tests: 11 tasks (all parallel after T002)
- Implementation: 5 tasks (sequential)
- Integration: 3 tasks (all parallel after T018)
- Polish: 3 tasks (sequential)

**Estimated Timeline**: 2-3 days
- Day 1: T001-T013 (Setup + All Tests)
- Day 2: T014-T018 (Bicep Implementation)
- Day 3: T019-T024 (Scripts + Polish)

## Validation Checklist
*GATE: Checked before task execution begins*

- [x] All contracts have corresponding tests (T003, T004)
- [x] All entities have model tasks (Hub=T014, Project=T015, AI Services=T016, Deployments=T017)
- [x] All tests come before implementation (T003-T013 before T014-T018)
- [x] Parallel tasks truly independent (different files, verified)
- [x] Each task specifies exact file path (all tasks include file paths)
- [x] No task modifies same file as another [P] task (verified - only main.bicep is sequential)
- [x] TDD ordering enforced (Phase 3.2 before 3.3)
- [x] Constitutional compliance maintained (single file <300 lines, tests first, Azure-native)

---

**Status**: Ready for implementation
**Next**: Execute tasks in order, starting with T001
**Constitutional Compliance**: ✅ Simplicity-First, ✅ Test-First Development, ✅ Azure-Native Integration, ✅ Clear Contracts, ✅ Observability
