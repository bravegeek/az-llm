# Azure AI Foundry Hub-less Infrastructure

Single-file Bicep deployment for Azure AI Foundry with hub-less architecture and 3 standard model deployments.

## Overview

This infrastructure deploys Azure AI Foundry using the **hub-less architecture** (2025 recommended pattern), which is simpler than the traditional Hub + Project model. The deployment includes:

- **1 AIServices Account** (kind: AIServices, S0 tier) - Enables project management without separate hub
- **1 AI Foundry Project** (child resource) - Workspace for model deployments
- **3 Standard Model Deployments** (200K TPM total, Bicep-deployed):
  1. `gpt-4` - GPT-4 model (50K TPM, version 1106-preview)
  2. `gpt-4o-mini` - Cost-effective mini model (100K TPM, version 2025-04-14)
  3. `gpt-4o` - High-performance GPT-4o (50K TPM, version 2024-08-06)

- **2 Serverless Models** (Manual deployment via portal):
  4. `FLUX-1.1-pro` - Image generation (serverless, pay-per-token)
  5. `DeepSeek-V3.1` - Alternative LLM (serverless, pay-per-token)

**Constitutional Compliance**: ✅ Single file (214 lines < 300), TDD validated, Azure-native, hub-less (simplest architecture)

## Prerequisites

- **Azure CLI** 2.50+ ([Install](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **Bicep CLI** 0.18+ (run `az bicep install`)
- **Azure Subscription** with AI Foundry access
- **Clean Resource Group** (deployment requires empty RG)
- **jq** - JSON processor for scripts ([Install](https://stedolan.github.io/jq/))
- **ajv-cli** (optional) - JSON Schema validation (`npm install -g ajv-cli`)

**Verify prerequisites**:
```bash
az --version | grep "azure-cli"
az bicep version
az account show --query "name" -o tsv
jq --version
```

## Quick Start

### 1. Configure Parameters

```bash
# Edit infra/main.parameters.json:
# - Set "aiServicesName" to globally unique name (e.g., "yourname-ai-foundry")
# - Set "customSubDomain" to globally unique subdomain (e.g., "yourname-ai")
# - Set "location" to your preferred region (e.g., "eastus2", "westus")
# - Optionally adjust TPM quotas (default: 50K, 100K, 50K)
```

**Example parameters**:
```json
{
  "location": { "value": "eastus2" },
  "aiServicesName": { "value": "my-ai-foundry" },
  "customSubDomain": { "value": "my-ai" },
  "projectName": { "value": "foundry-project" }
}
```

### 2. Validate Configuration

```bash
# Validate Bicep syntax, parameters, region, quota, and RG state
./scripts/validate.sh eastus2 rg-ai-foundry
```

**Validation checks**:
- ✅ Bicep syntax and ARM template build
- ✅ Parameter file structure and schema compliance
- ✅ Model availability in target region (gpt-4, gpt-4o-mini, gpt-4o)
- ✅ TPM quota availability (200K total)
- ✅ Resource group is empty (or doesn't exist)

### 3. Deploy Infrastructure

```bash
# Create deployment (5-10 minutes)
./scripts/deploy.sh rg-ai-foundry infra/main.parameters.json
```

**What gets deployed**:
1. AIServices account with SystemAssigned managed identity
2. AI Foundry Project (hub-less)
3. 3 model deployments (gpt-4, gpt-4o-mini, gpt-4o)

**Expected output**:
```
✅ Deployment complete!

📊 Deployment Outputs:
AI Services Resource ID: /subscriptions/.../Microsoft.CognitiveServices/accounts/my-ai-foundry
Project Resource ID: /subscriptions/.../accounts/my-ai-foundry/projects/foundry-project
Endpoint: https://my-ai.openai.azure.com/

Model Deployments:
  - gpt-4-deployment (gpt-4, 50K TPM)
  - gpt-4o-mini-deployment (gpt-4o-mini, 100K TPM)
  - gpt-4o-deployment (gpt-4o, 50K TPM)
```

### 4. Extract Outputs

```bash
# Generate .env.azure-foundry file
./scripts/outputs.sh rg-ai-foundry
```

**Generated `.env.azure-foundry` file**:
```bash
AI_SERVICES_ID=/subscriptions/.../accounts/my-ai-foundry
AI_SERVICES_ENDPOINT=https://my-ai.openai.azure.com/
GPT4_DEPLOYMENT_NAME=gpt-4-deployment
GPT4O_MINI_DEPLOYMENT_NAME=gpt-4o-mini-deployment
GPT4O_DEPLOYMENT_NAME=gpt-4o-deployment
FLUX_DEPLOYMENT_STATUS=manual-required
DEEPSEEK_DEPLOYMENT_STATUS=manual-required
```

### 5. Deploy Serverless Models (Manual)

**FLUX-1.1-pro and DeepSeek-V3.1 are serverless models that cannot be deployed via Bicep.** Deploy them manually:

1. Navigate to [Azure AI Foundry portal](https://ai.azure.com)
2. Select your project (`foundry-project`)
3. Go to **Model Catalog**
4. Search for `FLUX-1.1-pro`:
   - Click **Deploy** → **Serverless API**
   - Note the endpoint URL and API key
5. Search for `DeepSeek-V3.1`:
   - Click **Deploy** → **Serverless API**
   - Note the endpoint URL and API key
6. Update `.env.azure-foundry` with the serverless endpoints and keys

**Why manual?** Serverless models use pay-per-token billing (no TPM allocation) and deploy via a different API than standard models. Deploying via Bicep would exceed the 300-line simplicity constraint.

### 6. Run Tests

```bash
# Run all validation tests
export RESOURCE_GROUP=rg-ai-foundry
export AI_SERVICES_NAME=my-ai-foundry
bash tests/bicep/run-all-tests.sh
```

**Test suite includes**:
- ✅ Bicep linter and build validation
- ✅ Parameter and contract schema validation
- ✅ Infrastructure deployment validation (AIServices + Project + 3 models)
- ✅ Model TPM allocation verification (200K total)
- ✅ Output format compliance

## Architecture

### Hub-less vs Hub-based

**Hub-less (This deployment - Simpler)**:
```
AIServices Account (kind: AIServices, allowProjectManagement: true)
  ├── Project (child resource)
  └── Model Deployments (3× standard models)
```

**Hub-based (Legacy - More complex)**:
```
Hub (ML Workspace)
  ├── Project (ML Workspace)
  └── AIServices Account
      └── Model Deployments
```

**Why hub-less?**
- ✅ Simpler: 2 resources instead of 3
- ✅ Fewer permissions required
- ✅ Easier to manage and deploy
- ✅ Recommended for most scenarios (2025 best practice)

### Resource Hierarchy

```
CognitiveServices/accounts (AIServices)
├── Identity: SystemAssigned
├── Properties:
│   ├── customSubDomainName: <unique-subdomain>
│   ├── allowProjectManagement: true
│   └── publicNetworkAccess: Enabled
└── Child Resources:
    ├── projects/<project-name>
    └── deployments/
        ├── gpt-4-deployment
        ├── gpt-4o-mini-deployment
        └── gpt-4o-deployment
```

## File Structure

```
infra/
├── main.bicep              # Single-file infrastructure (214 lines)
├── main.parameters.json    # Deployment parameters (13 params)
└── README.md               # This file

scripts/
├── validate.sh             # Pre-deployment validation
├── deploy.sh               # Deployment automation
└── outputs.sh              # Extract outputs to .env

tests/bicep/
├── linter.test.sh                    # Bicep syntax validation
├── build.test.sh                     # ARM template build test
├── parameter-validation.test.sh      # Parameter schema test
├── contract-input.test.sh            # Input contract validation
├── contract-output.test.sh           # Output contract validation
├── quickstart-scenario-1.test.sh     # Infrastructure validation
├── quickstart-scenario-2.test.sh     # Model TPM validation
├── quickstart-scenario-3.test.sh     # Output format validation
├── quickstart-scenario-4.test.sh     # Endpoint connectivity
├── quickstart-scenario-5.test.sh     # Model availability validation
├── quickstart-scenario-6.test.sh     # Clean RG validation
└── run-all-tests.sh                  # Test orchestrator
```

## Troubleshooting

### Deployment Fails: "Location X does not support model Y"

**Solution**: Change region or remove unavailable model.

```bash
# Check which regions support all 3 models
az cognitiveservices model list --location eastus2 --query "[?name=='gpt-4' || name=='gpt-4o-mini' || name=='gpt-4o'].name" -o tsv
```

**Recommended regions**: `eastus`, `eastus2`, `westus`, `northcentralus`

### Deployment Fails: "Insufficient Quota"

**Solution**: Request quota increase or reduce TPM allocations.

```bash
# Check current quota usage
az cognitiveservices usage list --location eastus2 --query "[?contains(name.value, 'OpenAI')]"
```

**Request quota increase**: [Azure Portal](https://portal.azure.com) → Support → New Support Request → Service and subscription limits (quotas)

### Deployment Fails: "Resource Group Not Empty"

**Solution**: Use a clean resource group or delete existing resources.

```bash
# List resources
az resource list --resource-group rg-ai-foundry --output table

# Delete resource group (WARNING: Deletes all resources)
az group delete --name rg-ai-foundry --yes --no-wait
```

### Name Already Taken: "AIServices name X is not available"

**Solution**: Choose a different globally unique name.

**Name requirements**:
- 2-64 characters
- Alphanumeric and hyphens only
- Must be globally unique across Azure

**Example**: `my-company-ai-foundry-dev-20250101`

### Bicep Build Errors

**Solution**: Update Bicep CLI to latest version.

```bash
az bicep upgrade
az bicep version
```

## Cleanup

### Delete Deployment

```bash
# Delete entire resource group (WARNING: Irreversible)
az group delete --name rg-ai-foundry --yes

# Verify deletion
az group exists --name rg-ai-foundry
# Expected: false
```

### Archive Old Infrastructure

The previous Azure OpenAI infrastructure (15 files) has been archived to:
```
infra-archive/2025-10-20-azure-openai/
```

## Migration from Azure OpenAI

If migrating from the old Azure OpenAI standalone deployment, see [MIGRATION.md](../MIGRATION.md) for detailed migration steps and breaking changes.

**Key differences**:
- Old: Azure OpenAI standalone account
- New: AI Foundry AIServices account + Project
- Old: 5 models via Bicep (260K TPM)
- New: 3 models via Bicep (200K TPM) + 2 serverless (manual)
- Old: Single endpoint pattern
- New: Hub-less project pattern with same endpoint compatibility

## Additional Resources

- [Azure AI Foundry Documentation](https://learn.microsoft.com/azure/ai-studio/)
- [Bicep Language Reference](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/)
- [Hub-less Architecture Guide](https://learn.microsoft.com/azure/ai-studio/concepts/hub-less-architecture)

## Support

For issues or questions:
- Create an issue in the repository
- Review [quickstart scenarios](../specs/004-migrate-from-azure/quickstart.md)
- Check [test results](tests/bicep/run-all-tests.sh)

---

**Feature**: 004-migrate-from-azure | **Constitution**: v1.0.0 | **Bicep Version**: @2024-06-01-preview
