# Tasks: Minimal Single-File Bicep for OpenAI Provisioning

**Feature**: 003-create-a-minimal
**Branch**: `003-create-a-minimal`
**Date**: 2025-10-12
**Constitution**: v1.0.0

---

## Task Execution Rules

1. **TDD Order**: All Test Phase (T001-T015) MUST complete before Core Implementation (T016-T025)
2. **Parallel Tasks [P]**: Can execute concurrently (independent files)
3. **Sequential Tasks**: Must execute in order (shared dependencies)
4. **Red-Green-Refactor**: Tests MUST fail before implementation exists
5. **Completion Criteria**: Each task marked [X] only when fully working

---

## Phase 3.1: Setup (5 tasks)

### T001: Archive old infrastructure files [P]
**Status**: [X] Complete
**Type**: Setup
**Estimated Time**: 15 minutes

**Description**:
Move existing 15-file Bicep infrastructure to `infra-archive/2025-10-12-original/` to preserve history while making space for minimal single-file approach.

**Acceptance Criteria**:
- [ ] Directory `infra-archive/2025-10-12-original/` created
- [ ] Old files moved (modules/, environments/, bicepconfig.json, etc.)
- [ ] New files remain in infra/ (main.bicep, main.parameters.json, README.md placeholders)
- [ ] Git tracks the move operation

**Dependencies**: None
**Files Modified**: File system structure (archive operation)

**Implementation Notes**:
- Create archive directory: `mkdir -p infra-archive/2025-10-12-original`
- Move all old Bicep modules and configuration files
- Verify `infra/` only contains placeholder files for new minimal infrastructure
- Use `git mv` where possible to preserve history

---

### T002: Create test directory structure [P]
**Status**: [X] Complete
**Type**: Setup
**Estimated Time**: 5 minutes

**Description**:
Create `tests/bicep/` directory structure for TDD validation scripts.

**Acceptance Criteria**:
- [ ] Directory `tests/bicep/` exists
- [ ] Directory structure matches plan.md specification
- [ ] Git tracks the new directories

**Dependencies**: None
**Files Created**:
- `tests/bicep/` (directory)

**Implementation Notes**:
```bash
mkdir -p tests/bicep
```

---

### T003: Create scripts directory structure [P]
**Status**: [X] Complete
**Type**: Setup
**Estimated Time**: 5 minutes

**Description**:
Create `scripts/` directory for deployment automation scripts.

**Acceptance Criteria**:
- [ ] Directory `scripts/` exists
- [ ] Git tracks the new directory

**Dependencies**: None
**Files Created**:
- `scripts/` (directory)

**Implementation Notes**:
```bash
mkdir -p scripts
```

---

### T004: Create infra directory placeholders [P]
**Status**: [X] Complete
**Type**: Setup
**Estimated Time**: 5 minutes

**Description**:
Create placeholder files in `infra/` directory for main.bicep, main.parameters.json, README.md.

**Acceptance Criteria**:
- [ ] `infra/main.bicep` created (empty file with comment header)
- [ ] `infra/main.parameters.json` created (valid JSON skeleton)
- [ ] `infra/README.md` created (title only)

**Dependencies**: T001 (archive must complete first)
**Files Created**:
- `infra/main.bicep`
- `infra/main.parameters.json`
- `infra/README.md`

**Implementation Notes**:
- main.bicep: Add comment `// Minimal single-file Bicep for Azure OpenAI provisioning`
- main.parameters.json: Create valid JSON with empty parameters object
- README.md: Title "# Minimal Azure OpenAI Infrastructure"

---

### T005: Create contract validation test data [P]
**Status**: [X] Complete
**Type**: Setup
**Estimated Time**: 10 minutes

**Description**:
Create test fixtures for contract schema validation (valid and invalid parameter files).

**Acceptance Criteria**:
- [ ] `tests/bicep/fixtures/` directory created
- [ ] `valid-parameters.json` created (matches schema)
- [ ] `invalid-parameters.json` created (violates schema)

**Dependencies**: None
**Files Created**:
- `tests/bicep/fixtures/valid-parameters.json`
- `tests/bicep/fixtures/invalid-parameters.json`

**Implementation Notes**:
- valid-parameters.json: Use example from bicep-parameters.schema.json
- invalid-parameters.json: Missing required fields or invalid TPM values

---

## Phase 3.2: Test Phase - TDD REQUIRED (10 tasks)

### T006: Write Bicep syntax validation test (linter.test.sh) [P]
**Status**: [X] Complete
**Type**: Test
**Estimated Time**: 20 minutes

**Description**:
Create Bash script to validate Bicep syntax using `az bicep build --file infra/main.bicep`. Test MUST fail initially (file is empty placeholder).

**Acceptance Criteria**:
- [ ] Script `tests/bicep/linter.test.sh` created
- [ ] Script executable (`chmod +x`)
- [ ] Test fails with clear error message (empty/invalid Bicep)
- [ ] Exit code 1 on failure, 0 on success
- [ ] Output format: "✅ Syntax valid" or "❌ Syntax error: {details}"

**Dependencies**: T002, T004
**Files Created**:
- `tests/bicep/linter.test.sh`

**Implementation Notes**:
```bash
#!/bin/bash
set -e
az bicep build --file infra/main.bicep --stdout > /dev/null
echo "✅ Syntax valid"
```

**Red Phase**: Test fails because main.bicep is empty placeholder

---

### T007: Write Bicep build validation test (build.test.sh) [P]
**Status**: [X] Complete
**Type**: Test
**Estimated Time**: 20 minutes

**Description**:
Create Bash script to compile Bicep to ARM JSON and validate structure. Test MUST fail initially.

**Acceptance Criteria**:
- [ ] Script `tests/bicep/build.test.sh` created
- [ ] Script executable (`chmod +x`)
- [ ] Test fails (cannot compile empty Bicep)
- [ ] Validates compiled ARM JSON contains "resources" array
- [ ] Exit code 1 on failure, 0 on success

**Dependencies**: T002, T004
**Files Created**:
- `tests/bicep/build.test.sh`

**Implementation Notes**:
- Use `az bicep build --file infra/main.bicep --outfile /tmp/main.json`
- Validate JSON structure with `jq '.resources | length > 0'`

**Red Phase**: Test fails because main.bicep compiles to empty template

---

### T008: Write parameter validation test (parameter-validation.test.sh) [P]
**Status**: [X] Complete
**Type**: Test
**Estimated Time**: 30 minutes

**Description**:
Create Bash script to validate `main.parameters.json` against `bicep-parameters.schema.json` using JSON Schema validator. Test MUST fail initially (skeleton parameters).

**Acceptance Criteria**:
- [ ] Script `tests/bicep/parameter-validation.test.sh` created
- [ ] Script executable (`chmod +x`)
- [ ] Test fails on skeleton parameters (missing required fields)
- [ ] Uses `ajv` or `jsonschema` CLI for validation
- [ ] Exit code 1 on failure, 0 on success

**Dependencies**: T002, T004, T005
**Files Created**:
- `tests/bicep/parameter-validation.test.sh`

**Implementation Notes**:
- Install ajv-cli if not available: `npm install -g ajv-cli`
- Validate: `ajv validate -s specs/003-create-a-minimal/contracts/bicep-parameters.schema.json -d infra/main.parameters.json`

**Red Phase**: Test fails because main.parameters.json is empty skeleton

---

### T009: Write contract input schema validation test [P]
**Status**: [X] Complete
**Type**: Test
**Estimated Time**: 20 minutes

**Description**:
Create test to validate `bicep-parameters.schema.json` is valid JSON Schema draft-07. Test should pass (contract already exists).

**Acceptance Criteria**:
- [ ] Script `tests/bicep/contract-input.test.sh` created
- [ ] Script executable (`chmod +x`)
- [ ] Validates schema file against JSON Schema meta-schema
- [ ] Test passes (schema is valid)

**Dependencies**: T002
**Files Created**:
- `tests/bicep/contract-input.test.sh`

**Implementation Notes**:
- Use `ajv compile -s specs/003-create-a-minimal/contracts/bicep-parameters.schema.json`

**Green Phase**: Test passes immediately (contract schema already valid from /plan)

---

### T010: Write contract output schema validation test [P]
**Status**: [X] Complete
**Type**: Test
**Estimated Time**: 20 minutes

**Description**:
Create test to validate `deployment-outputs.schema.json` is valid JSON Schema draft-07. Test should pass (contract already exists).

**Acceptance Criteria**:
- [ ] Script `tests/bicep/contract-output.test.sh` created
- [ ] Script executable (`chmod +x`)
- [ ] Validates schema file against JSON Schema meta-schema
- [ ] Test passes (schema is valid)

**Dependencies**: T002
**Files Created**:
- `tests/bicep/contract-output.test.sh`

**Implementation Notes**:
- Use `ajv compile -s specs/003-create-a-minimal/contracts/deployment-outputs.schema.json`

**Green Phase**: Test passes immediately (contract schema already valid from /plan)

---

### T011: Write integration deployment test (deployment.test.sh)
**Status**: [X] Complete
**Type**: Test
**Estimated Time**: 30 minutes

**Description**:
Create Bash script for dry-run deployment using `az deployment group what-if`. Test MUST fail initially (Bicep not implemented).

**Acceptance Criteria**:
- [ ] Script `tests/bicep/deployment.test.sh` created
- [ ] Script executable (`chmod +x`)
- [ ] Test fails (what-if shows no resources to deploy)
- [ ] Accepts resource group name as parameter
- [ ] Exit code 1 on failure, 0 on success

**Dependencies**: T002, T004, T006, T007
**Files Created**:
- `tests/bicep/deployment.test.sh`

**Implementation Notes**:
```bash
#!/bin/bash
RESOURCE_GROUP=${1:-"test-rg"}
az deployment group what-if \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json
```

**Red Phase**: Test fails because Bicep has no resources defined

---

### T012: Write quickstart scenario 1 test stub [P]
**Status**: [X] Complete
**Type**: Test
**Estimated Time**: 15 minutes

**Description**:
Create test stub for Quickstart Scenario 1 (Fresh Deployment). Test MUST fail (no implementation).

**Acceptance Criteria**:
- [ ] Script `tests/bicep/quickstart-scenario-1.test.sh` created
- [ ] Script documents steps from quickstart.md Scenario 1
- [ ] Test fails with "NOT IMPLEMENTED" message
- [ ] Script executable

**Dependencies**: T002
**Files Created**:
- `tests/bicep/quickstart-scenario-1.test.sh`

**Implementation Notes**:
- Script should echo "Testing Scenario 1: Fresh Deployment"
- Exit with code 1 and message "NOT IMPLEMENTED - requires Bicep implementation"

**Red Phase**: Test fails by design (stub)

---

### T013: Write quickstart scenario 2-4 test stubs [P]
**Status**: [X] Complete
**Type**: Test
**Estimated Time**: 20 minutes

**Description**:
Create test stubs for Quickstart Scenarios 2, 3, 4 (Update Capacity, Migration, Quota Failure). Tests MUST fail (no implementation).

**Acceptance Criteria**:
- [ ] Scripts created: `quickstart-scenario-{2,3,4}.test.sh`
- [ ] Each documents steps from quickstart.md
- [ ] All fail with "NOT IMPLEMENTED" message
- [ ] All executable

**Dependencies**: T002
**Files Created**:
- `tests/bicep/quickstart-scenario-2.test.sh`
- `tests/bicep/quickstart-scenario-3.test.sh`
- `tests/bicep/quickstart-scenario-4.test.sh`

**Red Phase**: Tests fail by design (stubs)

---

### T014: Write quickstart scenario 5 test stub (5 models) [P]
**Status**: [X] Complete
**Type**: Test
**Estimated Time**: 25 minutes

**Description**:
Create test stub for Quickstart Scenario 5 (Multi-Model Verification). Test MUST fail (no implementation). Test validates all 5 models: gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1.

**Acceptance Criteria**:
- [ ] Script `tests/bicep/quickstart-scenario-5.test.sh` created
- [ ] Documents 6 substeps (5.1-5.6) from quickstart.md
- [ ] Test fails with "NOT IMPLEMENTED" message
- [ ] Script executable

**Dependencies**: T002
**Files Created**:
- `tests/bicep/quickstart-scenario-5.test.sh`

**Implementation Notes**:
- Echo "Testing Scenario 5: Multi-Model Deployment (5 models)"
- List all 5 model names in output
- Exit with code 1 and message "NOT IMPLEMENTED - requires Bicep + Docker implementation"

**Red Phase**: Test fails by design (stub)

---

### T015: Write quickstart scenario 6 test stub [P]
**Status**: [X] Complete
**Type**: Test
**Estimated Time**: 15 minutes

**Description**:
Create test stub for Quickstart Scenario 6 (End-to-End Open WebUI Integration). Test MUST fail (no implementation).

**Acceptance Criteria**:
- [ ] Script `tests/bicep/quickstart-scenario-6.test.sh` created
- [ ] Documents steps from quickstart.md Scenario 6
- [ ] Test fails with "NOT IMPLEMENTED" message
- [ ] Script executable

**Dependencies**: T002
**Files Created**:
- `tests/bicep/quickstart-scenario-6.test.sh`

**Red Phase**: Test fails by design (stub)

---

## Phase 3.3: Core Implementation (10 tasks)

### T016: Implement Bicep OpenAI account resource
**Status**: [X] Complete
**Type**: Implementation
**Estimated Time**: 30 minutes

**Description**:
Implement `Microsoft.CognitiveServices/accounts` resource in main.bicep for Azure OpenAI account.

**Acceptance Criteria**:
- [ ] OpenAI account resource defined in main.bicep
- [ ] Parameters for location, accountName, aiFoundryProjectName
- [ ] SKU set to 'S0'
- [ ] Kind set to 'OpenAI'
- [ ] customSubDomainName set to accountName
- [ ] publicNetworkAccess set to 'Enabled'
- [ ] T006 (linter test) now passes
- [ ] T007 (build test) now passes

**Dependencies**: T006, T007 (tests must exist and fail first)
**Files Modified**:
- `infra/main.bicep`

**Implementation Notes**:
```bicep
@description('Azure region for deployment')
param location string

@description('Globally unique name for OpenAI account')
param openAIAccountName string

@description('Optional AI Foundry project name')
param aiFoundryProjectName string = ''

resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIAccountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: openAIAccountName
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    aiFoundryProject: aiFoundryProjectName
  }
}
```

**Green Phase**: T006, T007 tests now pass

---

### T017: Implement Bicep model deployment resources (5 models)
**Status**: [X] Complete
**Type**: Implementation
**Estimated Time**: 45 minutes

**Description**:
Implement 5 `Microsoft.CognitiveServices/accounts/deployments` child resources for: gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1.

**Acceptance Criteria**:
- [ ] 5 deployment resources defined as child resources of openAIAccount
- [ ] Parameters for all 15 model configuration fields (3 per model)
- [ ] Each deployment has model.format = 'OpenAI'
- [ ] Each deployment has sku.name = 'Standard'
- [ ] Capacity (TPM) set per parameter
- [ ] Default TPM allocations: gpt41=50, gpt41Mini=100, gpt4o=50, flux=10, deepseek=50

**Dependencies**: T016 (OpenAI account must exist)
**Files Modified**:
- `infra/main.bicep`

**Implementation Notes**:
```bicep
// Parameters for all 5 models (15 total parameters)
@description('GPT-4.1 model name')
param gpt41ModelName string = 'gpt-4.1'

@description('GPT-4.1 model version')
param gpt41ModelVersion string = '0409'

@description('GPT-4.1 capacity (TPM)')
@minValue(1)
@maxValue(1000)
param gpt41CapacityTPM int = 50

// ... repeat for gpt41Mini, gpt4o, flux, deepseek ...

resource gpt41Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAIAccount
  name: 'gpt-4.1'
  sku: {
    name: 'Standard'
    capacity: gpt41CapacityTPM
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt41ModelName
      version: gpt41ModelVersion
    }
  }
}

// ... repeat for other 4 models ...
```

**Green Phase**: Bicep builds successfully with all 5 deployments

---

### T018: Implement Bicep outputs (5 models)
**Status**: [X] Complete
**Type**: Implementation
**Estimated Time**: 20 minutes

**Description**:
Implement output section in main.bicep to expose endpoint, apiKey, resourceId, deploymentNames (array of 5), location.

**Acceptance Criteria**:
- [ ] Output `endpoint` returns OpenAI API endpoint URL
- [ ] Output `apiKey` returns primary key via listKeys()
- [ ] Output `resourceId` returns full ARM resource ID
- [ ] Output `deploymentNames` returns array of 5 deployment names
- [ ] Output `location` returns deployed region
- [ ] Outputs match deployment-outputs.schema.json contract

**Dependencies**: T016, T017 (resources must exist)
**Files Modified**:
- `infra/main.bicep`

**Implementation Notes**:
```bicep
output endpoint string = openAIAccount.properties.endpoint
output apiKey string = openAIAccount.listKeys().key1
output resourceId string = openAIAccount.id
output deploymentNames array = [
  gpt41Deployment.name
  gpt41MiniDeployment.name
  gpt4oDeployment.name
  fluxDeployment.name
  deepseekDeployment.name
]
output location string = location
output accountName string = openAIAccount.name
```

---

### T019: Populate main.parameters.json (5 models)
**Status**: [X] Complete
**Type**: Implementation
**Estimated Time**: 20 minutes

**Description**:
Populate `infra/main.parameters.json` with default values for all 17 required parameters (5 models × 3 params each + 2 global params).

**Acceptance Criteria**:
- [ ] Valid ARM parameters file structure
- [ ] All 17 required parameters from bicep-parameters.schema.json included
- [ ] Default values match schema defaults
- [ ] File validates against bicep-parameters.schema.json
- [ ] T008 (parameter validation test) now passes

**Dependencies**: T008 (test must exist and fail first), T016, T017
**Files Modified**:
- `infra/main.parameters.json`

**Implementation Notes**:
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": { "value": "eastus2" },
    "openAIAccountName": { "value": "bg-llm-minimal" },
    "aiFoundryProjectName": { "value": "bg-llm-01" },
    "gpt41ModelName": { "value": "gpt-4.1" },
    "gpt41ModelVersion": { "value": "0409" },
    "gpt41CapacityTPM": { "value": 50 },
    "gpt41MiniModelName": { "value": "gpt-4o-mini" },
    "gpt41MiniModelVersion": { "value": "2024-07-18" },
    "gpt41MiniCapacityTPM": { "value": 100 },
    "gpt4oModelName": { "value": "gpt-4o" },
    "gpt4oModelVersion": { "value": "2024-08-06" },
    "gpt4oCapacityTPM": { "value": 50 },
    "fluxModelName": { "value": "FLUX-1.1-pro" },
    "fluxModelVersion": { "value": "2024-11-04" },
    "fluxCapacityTPM": { "value": 10 },
    "deepseekModelName": { "value": "DeepSeek-V3.1" },
    "deepseekModelVersion": { "value": "2024-05-01" },
    "deepseekCapacityTPM": { "value": 50 }
  }
}
```

**Green Phase**: T008 parameter validation test now passes

---

### T020: Implement deploy.sh script
**Status**: [X] Complete
**Type**: Implementation
**Estimated Time**: 30 minutes

**Description**:
Create deployment automation script that runs `az deployment group create` with proper error handling.

**Acceptance Criteria**:
- [ ] Script accepts resource group name and parameters file as arguments
- [ ] Validates prerequisites (Azure CLI logged in, Bicep installed)
- [ ] Runs deployment with `--output json` for structured logging
- [ ] Displays deployment outputs (endpoint, API key redacted)
- [ ] Exit code 0 on success, non-zero on failure
- [ ] Script <100 lines (constitutional requirement)

**Dependencies**: T003, T016, T017, T018, T019
**Files Created**:
- `scripts/deploy.sh`

**Implementation Notes**:
```bash
#!/bin/bash
set -euo pipefail

RESOURCE_GROUP=${1:?"ERROR: Resource group name required"}
PARAMETERS_FILE=${2:?"ERROR: Parameters file required"}

echo "🚀 Deploying minimal Azure OpenAI infrastructure..."

az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infra/main.bicep \
  --parameters "$PARAMETERS_FILE" \
  --output json > /tmp/deployment.json

echo "✅ Deployment complete"
jq -r '.properties.outputs' /tmp/deployment.json
```

---

### T021: Implement validate.sh script
**Status**: [X] Complete
**Type**: Implementation
**Estimated Time**: 20 minutes

**Description**:
Create pre-deployment validation script that runs linter, build, and parameter validation tests.

**Acceptance Criteria**:
- [ ] Runs T006 (linter test)
- [ ] Runs T007 (build test)
- [ ] Runs T008 (parameter validation test)
- [ ] Stops on first failure
- [ ] Exit code 0 if all pass, non-zero on failure
- [ ] Script <50 lines

**Dependencies**: T003, T006, T007, T008
**Files Created**:
- `scripts/validate.sh`

**Implementation Notes**:
```bash
#!/bin/bash
set -e

echo "🔍 Validating Bicep infrastructure..."

./tests/bicep/linter.test.sh
./tests/bicep/build.test.sh
./tests/bicep/parameter-validation.test.sh

echo "✅ All validation checks passed"
```

---

### T022: Implement outputs.sh script (5 models)
**Status**: [X] Complete
**Type**: Implementation
**Estimated Time**: 30 minutes

**Description**:
Create script to extract deployment outputs and generate `.env.azure-openai` file with 7 environment variables (endpoint, apiKey, 5 deployment names).

**Acceptance Criteria**:
- [ ] Accepts resource group name as argument
- [ ] Queries deployment outputs using `az deployment group show`
- [ ] Generates `.env.azure-openai` file with 7 variables
- [ ] Variables: AZURE_OPENAI_ENDPOINT, AZURE_API_KEY, GPT41_DEPLOYMENT_NAME, GPT41_MINI_DEPLOYMENT_NAME, GPT4O_DEPLOYMENT_NAME, FLUX_DEPLOYMENT_NAME, DEEPSEEK_DEPLOYMENT_NAME
- [ ] Validates outputs against deployment-outputs.schema.json
- [ ] Script <80 lines

**Dependencies**: T003, T018 (outputs must exist), T010 (output schema test)
**Files Created**:
- `scripts/outputs.sh`

**Implementation Notes**:
```bash
#!/bin/bash
set -euo pipefail

RESOURCE_GROUP=${1:?"ERROR: Resource group name required"}
DEPLOYMENT_NAME=${2:-"main"}

az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$DEPLOYMENT_NAME" \
  --query 'properties.outputs' \
  --output json > /tmp/outputs.json

# Extract values
ENDPOINT=$(jq -r '.endpoint.value' /tmp/outputs.json)
API_KEY=$(jq -r '.apiKey.value' /tmp/outputs.json)
DEPLOYMENTS=($(jq -r '.deploymentNames.value[]' /tmp/outputs.json))

# Generate .env file
cat > .env.azure-openai <<EOF
AZURE_OPENAI_ENDPOINT=$ENDPOINT
AZURE_API_KEY=$API_KEY
GPT41_DEPLOYMENT_NAME=${DEPLOYMENTS[0]}
GPT41_MINI_DEPLOYMENT_NAME=${DEPLOYMENTS[1]}
GPT4O_DEPLOYMENT_NAME=${DEPLOYMENTS[2]}
FLUX_DEPLOYMENT_NAME=${DEPLOYMENTS[3]}
DEEPSEEK_DEPLOYMENT_NAME=${DEPLOYMENTS[4]}
EOF

echo "✅ Outputs extracted to .env.azure-openai"
```

---

### T023: Implement infra/README.md
**Status**: [X] Complete
**Type**: Implementation
**Estimated Time**: 30 minutes

**Description**:
Write comprehensive README for infrastructure deployment covering prerequisites, quickstart, and troubleshooting.

**Acceptance Criteria**:
- [ ] Prerequisites section (Azure CLI, Bicep CLI versions)
- [ ] Quick start deployment steps
- [ ] Parameter configuration examples
- [ ] Troubleshooting common errors
- [ ] Links to quickstart.md for full scenarios
- [ ] Mentions all 5 models deployed

**Dependencies**: T020, T021, T022
**Files Modified**:
- `infra/README.md`

**Implementation Notes**:
- Structure: Prerequisites → Quick Start → Configuration → Outputs → Troubleshooting
- Include examples for all 5 models
- Reference quickstart.md for integration tests
- Document TPM quota considerations (260 TPM total default)

---

### T024: Run all test validations (Green Phase)
**Status**: [ ] Pending
**Type**: Validation
**Estimated Time**: 15 minutes

**Description**:
Execute all Phase 3.2 tests (T006-T015) to verify they now pass (Green Phase of TDD).

**Acceptance Criteria**:
- [ ] T006 linter test passes
- [ ] T007 build test passes
- [ ] T008 parameter validation test passes
- [ ] T009 contract input test passes
- [ ] T010 contract output test passes
- [ ] T011 deployment what-if test passes
- [ ] All quickstart stubs still fail (intentional - need integration work)

**Dependencies**: T006-T015, T016-T023
**Files Modified**: None (validation only)

**Implementation Notes**:
```bash
./scripts/validate.sh  # Should pass all tests
./tests/bicep/deployment.test.sh <test-resource-group>  # Should show 6 resources
```

---

### T025: Update CLAUDE.md with new infrastructure paths
**Status**: [ ] Pending
**Type**: Documentation
**Estimated Time**: 10 minutes

**Description**:
Update CLAUDE.md to document new minimal infrastructure structure (infra/, scripts/, tests/bicep/).

**Acceptance Criteria**:
- [ ] Project structure section updated with new paths
- [ ] Old infrastructure archive location documented
- [ ] Script locations documented
- [ ] Test structure documented

**Dependencies**: T001-T024
**Files Modified**:
- `CLAUDE.md`

**Implementation Notes**:
- Add under "Technology Stack" or "Project Structure" section
- Document 5 model deployment approach
- Note constitutional compliance (single file <300 lines, TDD followed)

---

## Phase 3.4: Integration (5 tasks)

### T026: Create .env.example file (5 models)
**Status**: [ ] Pending
**Type**: Integration
**Estimated Time**: 10 minutes

**Description**:
Create `.env.example` template file showing 7 required environment variables for Docker integration.

**Acceptance Criteria**:
- [ ] File `.env.example` created in repository root
- [ ] Contains placeholders for 7 variables
- [ ] Includes comments explaining each variable
- [ ] Documents which variable maps to which model

**Dependencies**: T022
**Files Created**:
- `.env.example`

**Implementation Notes**:
```bash
# Azure OpenAI Configuration (generated by scripts/outputs.sh)
AZURE_OPENAI_ENDPOINT=https://your-account.openai.azure.com/
AZURE_API_KEY=your-32-character-api-key

# Model Deployment Names (5 models)
GPT41_DEPLOYMENT_NAME=gpt-4.1           # Primary GPT model
GPT41_MINI_DEPLOYMENT_NAME=gpt-4.1-mini # Cost-effective GPT
GPT4O_DEPLOYMENT_NAME=gpt-4o            # High-performance GPT
FLUX_DEPLOYMENT_NAME=FLUX-1.1-pro       # Image generation
DEEPSEEK_DEPLOYMENT_NAME=DeepSeek-V3.1  # Alternative LLM
```

---

### T027: Update docker/litellm/config.yaml template (5 models)
**Status**: [ ] Pending
**Type**: Integration
**Estimated Time**: 20 minutes

**Description**:
Update LiteLLM configuration to reference new Azure OpenAI endpoint and 5 model deployments.

**Acceptance Criteria**:
- [ ] 5 model entries in config.yaml
- [ ] Each model references correct deployment name via environment variable
- [ ] api_base set to `os.environ/AZURE_OPENAI_ENDPOINT`
- [ ] api_key set to `os.environ/AZURE_API_KEY`
- [ ] api_version set to '2024-02-15-preview'

**Dependencies**: T026
**Files Modified**:
- `docker/litellm/config.yaml`

**Implementation Notes**:
```yaml
model_list:
  - model_name: gpt-4.1
    litellm_params:
      model: azure/${GPT41_DEPLOYMENT_NAME}
      api_base: os.environ/AZURE_OPENAI_ENDPOINT
      api_key: os.environ/AZURE_API_KEY
      api_version: "2024-02-15-preview"

  - model_name: gpt-4.1-mini
    litellm_params:
      model: azure/${GPT41_MINI_DEPLOYMENT_NAME}
      api_base: os.environ/AZURE_OPENAI_ENDPOINT
      api_key: os.environ/AZURE_API_KEY
      api_version: "2024-02-15-preview"

  # ... repeat for gpt4o, flux, deepseek ...
```

---

### T028: Implement quickstart scenario tests (replace stubs)
**Status**: [ ] Pending
**Type**: Integration
**Estimated Time**: 60 minutes

**Description**:
Replace quickstart test stubs (T012-T015) with actual integration test implementations for all 6 scenarios.

**Acceptance Criteria**:
- [ ] Scenario 1 test performs fresh deployment and validates outputs
- [ ] Scenario 2 test modifies capacity and verifies idempotency
- [ ] Scenario 3 test validates migration steps
- [ ] Scenario 4 test intentionally exceeds quota and validates failure
- [ ] Scenario 5 test validates all 5 models accessible via LiteLLM
- [ ] Scenario 6 test validates Open WebUI integration
- [ ] All tests executable and self-contained

**Dependencies**: T012-T015 (stubs), T020 (deploy.sh), T022 (outputs.sh), T027 (Docker config)
**Files Modified**:
- `tests/bicep/quickstart-scenario-1.test.sh`
- `tests/bicep/quickstart-scenario-2.test.sh`
- `tests/bicep/quickstart-scenario-3.test.sh`
- `tests/bicep/quickstart-scenario-4.test.sh`
- `tests/bicep/quickstart-scenario-5.test.sh` (5 models)
- `tests/bicep/quickstart-scenario-6.test.sh`

**Implementation Notes**:
- Follow steps from quickstart.md exactly
- Each scenario should be runnable independently
- Scenario 5 must test all 5 models individually
- Use `set -e` for fail-fast behavior
- Clean up test resources after execution

---

### T029: Execute end-to-end validation
**Status**: [ ] Pending
**Type**: Validation
**Estimated Time**: 45 minutes

**Description**:
Run all 6 quickstart scenarios end-to-end against test Azure resource group to verify complete workflow.

**Acceptance Criteria**:
- [ ] Scenario 1 (Fresh Deploy) passes - 5 models deployed
- [ ] Scenario 2 (Update Capacity) passes - idempotent update
- [ ] Scenario 3 (Migration) passes - old archived, new working
- [ ] Scenario 4 (Quota Failure) passes - graceful error handling
- [ ] Scenario 5 (Multi-Model) passes - all 5 models accessible
- [ ] Scenario 6 (End-to-End) passes - Open WebUI functional
- [ ] All acceptance criteria from quickstart.md satisfied

**Dependencies**: T028, Azure test resource group
**Files Modified**: None (validation only)

**Implementation Notes**:
- Create dedicated test resource group: `az-llm-003-test`
- Run each scenario in sequence
- Capture logs for troubleshooting
- Clean up test resources after validation
- Document any deviations from expected behavior

---

### T030: Finalize documentation
**Status**: [ ] Pending
**Type**: Documentation
**Estimated Time**: 20 minutes

**Description**:
Update plan.md Progress Tracking, mark feature complete, update README with final deployment instructions.

**Acceptance Criteria**:
- [ ] plan.md Progress Tracking shows all phases complete
- [ ] Repository root README updated with new infrastructure section
- [ ] All 5 models documented
- [ ] Migration guide from old infrastructure documented
- [ ] Constitutional compliance confirmed

**Dependencies**: T029 (all tests passing)
**Files Modified**:
- `specs/003-create-a-minimal/plan.md`
- `README.md` (repository root)

**Implementation Notes**:
- plan.md: Mark Phase 3, 4, 5 complete
- README: Add "Minimal Azure OpenAI Infrastructure" section
- Document total TPM capacity (260)
- Confirm single Bicep file <300 lines
- Note TDD followed throughout

---

## Summary

**Total Tasks**: 30
**Parallel Tasks**: 12 (marked [P] in Setup and Test phases)
**Sequential Tasks**: 18 (dependencies between phases)

**Estimated Time Breakdown**:
- Phase 3.1 Setup: 40 minutes (5 tasks, mostly parallel)
- Phase 3.2 Tests: 3 hours (10 tasks, mostly parallel, TDD red phase)
- Phase 3.3 Core: 4 hours (10 tasks, sequential, TDD green phase)
- Phase 3.4 Integration: 2.5 hours (5 tasks, sequential validation)
- **Total**: ~10 hours

**Constitutional Compliance**:
- ✅ Test-First Development: Phase 3.2 completes before 3.3
- ✅ Simplicity-First: Single Bicep file, <100 line scripts
- ✅ Azure-Native: Bicep, Azure CLI, Azure OpenAI Service
- ✅ Clear Contracts: JSON Schema validation in tests
- ✅ Observability: Deployment logs, test results, quickstart scenarios

**Next Step**: Execute `/implement` command or manually work through tasks T001-T030 in order

---
*Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`*
