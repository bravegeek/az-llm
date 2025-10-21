# Research: Azure AI Foundry Hub-less Deployment

**Feature**: 004-migrate-from-azure
**Date**: 2025-10-20
**Status**: Complete

## Overview

This research identifies the correct Azure AI Foundry hub-less architecture (2025) for deploying 5 models to a clean resource group using single-file Bicep infrastructure.

## 1. Azure AI Foundry Hub-less Architecture

### Decision
Use `Microsoft.CognitiveServices/accounts` with `kind: 'AIServices'` and child `projects` resource.

### Rationale
- **Hub-less is simpler**: Recommended 2025 architecture for AI Foundry unless specific hub features needed
- **Single-tier hierarchy**: AIServices account → Project (vs hub-based: Hub → Project → Deployments)
- **Constitutional compliance**: Aligns with Simplicity-First principle

### Bicep Resource Types
- **Parent (AIServices Account)**: `Microsoft.CognitiveServices/accounts@2025-06-01`
- **Child (Project)**: `Microsoft.CognitiveServices/accounts/projects@2025-06-01`

### Bicep Example
```bicep
resource aiServices 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: 'ai-foundry-${uniqueString(resourceGroup().id)}'
  kind: 'AIServices'
  location: location
  sku: {
    name: 'S0'  // Standard SKU
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true  // REQUIRED for hub-less projects
    customSubDomainName: 'ai-${uniqueString(resourceGroup().id)}'  // REQUIRED
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
}

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: aiServices
  name: 'foundry-project'
  location: location
  properties: {
    displayName: 'AI Foundry Project'
    description: 'Hub-less project for model deployments'
  }
}
```

### Required Properties
- **allowProjectManagement**: `true` (enables projects within AIServices account)
- **customSubDomainName**: Unique subdomain for endpoints
- **kind**: `'AIServices'` (not Hub or Project)

### Auto-created Properties
- Resource IDs (id, projectId)
- Endpoints (from customSubDomainName)
- System-assigned managed identity principal ID
- Timestamps (createdTime, provisioningState)

### Alternatives Considered
- **Hub-based architecture** (`Microsoft.MachineLearningServices/workspaces`): Rejected - more complex, requires separate Hub and Project resources
- **Standalone OpenAI resource**: Rejected - not AI Foundry architecture

## 2. Model Deployment in AI Foundry

### Decision
Deploy models as child resources of CognitiveServices account using `Microsoft.CognitiveServices/accounts/deployments`.

### Rationale
- **Direct to account**: Deployments are account-level resources (parent is AIServices, not project)
- **Standard pattern**: Consistent with Azure OpenAI deployment model
- **Bicep-native**: Fully supported in Bicep templates

### Bicep Resource Type
```bicep
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiServices  // Parent is AIServices account
  name: 'gpt-41-deployment'
  sku: {
    name: 'Standard'  // or 'DataZoneStandard' for newer models
    capacity: 50  // TPM in thousands (50 = 50K TPM)
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '1106-preview'
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
    raiPolicyName: 'Microsoft.Default'
  }
}
```

### TPM Allocation
- **Property**: `sku.capacity`
- **Unit**: Thousands of TPM (capacity: 50 = 50,000 TPM)
- **Increment**: 1,000 TPM (use integers: 1, 10, 50, 100)
- **Project allocation**: gpt-4.1=50, gpt-4.1-mini=100, gpt-4o=50, FLUX-1.1-pro=10, DeepSeek-V3.1=50

### Model-Specific Versions
- **gpt-4.1** (gpt-4): `name: 'gpt-4'`, `version: '1106-preview'`
- **gpt-4.1-mini** (gpt-4o-mini): `name: 'gpt-4o-mini'`, `version: '2025-04-14'`
- **gpt-4o**: `name: 'gpt-4o'`, `version: '2024-08-06'`
- **FLUX-1.1-pro**: Serverless API (see note below)
- **DeepSeek-V3.1**: Serverless API (see note below)

### Critical Discovery: Serverless Models
**FLUX-1.1-pro and DeepSeek-V3.1 use serverless API deployment, NOT standard deployments**:
- **No TPM allocation**: Pay-per-token billing
- **Different deployment type**: Not deployable via standard Bicep deployments
- **Model catalog**: Available through Azure AI Foundry portal model catalog
- **Deployment method**: Portal or `az ml` commands (not `az cognitiveservices`)

**Impact on Bicep design**: Cannot deploy all 5 models via single Bicep template. Options:
1. Deploy 3 standard models (gpt-4, gpt-4o-mini, gpt-4o) via Bicep
2. Document FLUX and DeepSeek as manual portal deployments
3. Use Azure ML CLI extension for serverless deployments (outside Bicep)

**Recommended approach**: Document serverless models as manual post-deployment step to maintain <300 line Bicep constraint.

### Alternatives Considered
- **Deploy to project resource**: Rejected - Projects don't support child deployments
- **MachineLearningServices deployments**: Rejected - Wrong resource hierarchy for hub-less
- **Provisioned throughput (PTU)**: Rejected - More complex than standard TPM

## 3. Model Availability Validation

### Decision
Use `az cognitiveservices model list` for standard models; document serverless models as manual validation.

### Azure CLI Command
```bash
# List all models available in region
az cognitiveservices model list \
  --location eastus2 \
  --output table

# Check specific model
az cognitiveservices model list \
  --location eastus2 \
  --query "[?name=='gpt-4o']" \
  --output json
```

### Validation Script Pattern
```bash
#!/bin/bash
REGION="eastus2"
MODELS=("gpt-4o" "gpt-4o-mini" "gpt-4")

for model in "${MODELS[@]}"; do
  available=$(az cognitiveservices model list \
    --location "$REGION" \
    --query "[?name=='$model'].name" \
    --output tsv)

  if [ -z "$available" ]; then
    echo "ERROR: Model $model not available in $REGION"
    exit 1
  fi
  echo "✓ Model $model available"
done
```

### Serverless Model Validation
- **FLUX-1.1-pro**: Check Azure AI Foundry portal model catalog manually
- **DeepSeek-V3.1**: Check Azure AI Foundry portal model catalog manually
- **No CLI command**: Serverless models not queryable via `az cognitiveservices`
- **Recommendation**: Document as manual prerequisite

### Alternatives Considered
- **REST API queries**: Rejected - requires authentication token management, complex
- **Skip validation**: Rejected - causes deployment failures with unclear errors

## 4. TPM Quota Validation

### Decision
Use `az cognitiveservices usage list` with region parameter in deployment script.

### Azure CLI Command
```bash
# Check quota/usage for region
az cognitiveservices usage list \
  --location "eastus2" \
  --output json
```

### Output Structure
```json
[
  {
    "currentValue": 0.0,
    "limit": 100.0,
    "name": {
      "localizedValue": "Tokens Per Minute (thousands) - GPT-4o",
      "value": "OpenAI.Standard.gpt-4o"
    },
    "unit": "Count"
  }
]
```

### Validation Script Pattern
```bash
check_quota() {
  local model=$1
  local required_tpm=$2
  local region=$3

  local available=$(az cognitiveservices usage list \
    --location "$region" \
    --query "[?name.value=='OpenAI.Standard.$model'] | [0] | (limit - currentValue)" \
    --output tsv)

  if (( $(echo "$available < $required_tpm" | bc -l) )); then
    echo "ERROR: Insufficient quota for $model"
    echo "  Available: ${available}K TPM, Required: ${required_tpm}K TPM"
    return 1
  fi

  echo "✓ Quota OK for $model"
}

check_quota "gpt-4o" 50 "eastus2"
check_quota "gpt-4o-mini" 100 "eastus2"
```

### Total Quota Requirement
- **gpt-4.1**: 50K TPM
- **gpt-4.1-mini**: 100K TPM
- **gpt-4o**: 50K TPM
- **FLUX-1.1-pro**: N/A (serverless, pay-per-token)
- **DeepSeek-V3.1**: N/A (serverless, pay-per-token)
- **Total standard TPM**: 200K TPM

### Alternatives Considered
- **Portal-only validation**: Rejected - not automatable
- **Skip quota check**: Rejected - causes obscure deployment failures
- **ARM what-if**: Rejected - doesn't validate quota

## 5. Clean Resource Group Validation

### Decision
Validate using `az resource list` with count check; implement in deployment script (not Bicep).

### Rationale
- **Bicep limitation**: No conditional deployment based on existing resources (by design)
- **Azure pattern**: Pre-deployment validation via scripts or pipelines
- **Idempotency**: Bicep deployments are additive; empty RG check must be external

### Bash Validation Script
```bash
#!/bin/bash
RESOURCE_GROUP="my-rg"

# Check RG exists
if ! az group exists --name "$RESOURCE_GROUP" | grep -q true; then
  echo "ERROR: Resource group $RESOURCE_GROUP does not exist"
  exit 1
fi

# Check RG is empty
resource_count=$(az resource list \
  --resource-group "$RESOURCE_GROUP" \
  --query "length(@)" \
  --output tsv)

if [ "$resource_count" -ne 0 ]; then
  echo "ERROR: Resource group contains $resource_count resources"
  echo "  Clean deployment required"
  az resource list --resource-group "$RESOURCE_GROUP" --output table
  exit 1
fi

echo "✓ Resource group is empty"
```

### Integration in deploy.sh
```bash
#!/bin/bash
set -euo pipefail

RESOURCE_GROUP="${1:-}"
LOCATION="${2:-eastus2}"

# Validate empty RG
count=$(az resource list -g "$RESOURCE_GROUP" --query "length(@)" -o tsv)
if [ "$count" -ne 0 ]; then
  echo "ERROR: Resource group contains $count resources"
  exit 1
fi

# Continue with deployment
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file infra/main.bicep \
  --parameters infra/main.parameters.json
```

### Why Not in Bicep
- Bicep has no "fail if resources exist" capability
- `existing` keyword is for referencing resources, not validation
- ARM deployment mode `Complete` deletes existing resources (dangerous)
- Pre-deployment validation is the correct pattern

### Alternatives Considered
- **Bicep conditions**: Rejected - no query/count functions for existing resources
- **ARM Complete mode**: Rejected - destructive
- **Azure Policy**: Rejected - overkill for simple validation

## Summary of Decisions

| Topic | Decision | Implementation |
|-------|----------|----------------|
| **Architecture** | Hub-less AIServices + Projects | `Microsoft.CognitiveServices/accounts@2025-06-01` |
| **Model Deployments** | Standard TPM for 3 models, serverless for 2 | Bicep for standard, manual for serverless |
| **TPM Allocation** | 200K TPM for 3 standard models | sku.capacity in deployments resource |
| **Model Validation** | CLI for standard, manual for serverless | `az cognitiveservices model list` in validate.sh |
| **Quota Validation** | CLI quota check before deployment | `az cognitiveservices usage list` in validate.sh |
| **Clean RG Validation** | Bash script pre-deployment check | `az resource list` count check in deploy.sh |

## Impact on Spec Requirements

### Spec Compliance
- **FR-001** ✅: Hub-less AI Foundry project (CognitiveServices account)
- **FR-002** ⚠️: **Cannot deploy all 5 models via Bicep** (FLUX and DeepSeek are serverless)
- **FR-003** ⚠️: **TPM allocation only for 3 models** (200K total, not 260K)
- **FR-005** ✅: Single-file Bicep (<300 lines)
- **FR-011** ✅: Model availability validation (standard models only)
- **FR-012** ✅: TPM quota validation
- **FR-013** ✅: Clean resource group validation

### Required Spec Updates
**FR-002 and FR-003 need clarification**:
- Option 1: Deploy only 3 standard OpenAI models via Bicep, document FLUX/DeepSeek as manual
- Option 2: Remove FLUX/DeepSeek from requirements (simplify to 3 models)
- Option 3: Add Azure ML CLI extension for serverless deployments (increases complexity)

**Recommendation**: Update spec to Option 1 (3 models in Bicep, 2 serverless as manual steps) to maintain <300 line constraint and simplicity.

## Next Steps (Phase 1)

1. Create data-model.md with 3 standard model deployments
2. Generate contracts for input (3 models) and output schemas
3. Update quickstart scenarios to reflect serverless manual deployment
4. Generate Bicep template for AIServices + 3 standard deployments
5. Create deployment scripts with all 5 validation checks

---

**Status**: Ready for Phase 1 (Design & Contracts)
