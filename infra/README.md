# Minimal Azure OpenAI Infrastructure

Single-file Bicep deployment for Azure OpenAI Service with 5 model deployments.

## Overview

This minimal infrastructure replaces the previous 15-file Bicep setup with a single `main.bicep` file that deploys:

- **1 Azure OpenAI Account** (S0 tier)
- **5 Model Deployments** (total 260 TPM):
  1. `gpt-4.1` - Primary GPT model (50 TPM)
  2. `gpt-4.1-mini` - Cost-effective GPT (100 TPM)
  3. `gpt-4o` - High-performance multimodal (50 TPM)
  4. `FLUX-1.1-pro` - Image generation (10 TPM)
  5. `DeepSeek-V3.1` - Alternative LLM (50 TPM)

**Constitutional Compliance**: ✅ Single file (214 lines < 300), TDD validated, Azure-native

## Prerequisites

- **Azure CLI** 2.50+ ([Install](https://docs.microsoft.com/cli/azure/install-azure-cli))
- **Bicep CLI** 0.18+ (run `az bicep install`)
- **Azure Subscription** with OpenAI service enabled
- **Resource Group** (existing or create new)

**Verify prerequisites**:
```bash
az --version | grep "azure-cli"
az bicep version
az account show --query "name" -o tsv
```

## Quick Start

### 1. Configure Parameters

```bash
# Copy parameters template
cp infra/main.parameters.json infra/main.parameters.local.json

# Edit main.parameters.local.json:
# - Set "openAIAccountName" to globally unique name (e.g., "yourname-llm-dev")
# - Set "location" to your preferred region (e.g., "eastus2", "westus3")
# - Adjust TPM quotas if needed (default total: 260 TPM)
```

### 2. Validate Configuration

```bash
./scripts/validate.sh
```

Expected output:
```
✅ Syntax valid
✅ Build valid
✅ Parameters valid
```

### 3. Deploy Infrastructure

```bash
# Login to Azure
az login

# Create resource group (if needed)
az group create --name my-openai-rg --location eastus2

# Deploy
./scripts/deploy.sh my-openai-rg @infra/main.parameters.local.json
```

Deployment time: ~5-7 minutes

### 4. Extract Outputs

```bash
./scripts/outputs.sh my-openai-rg
```

This creates `.env.azure-openai` with 7 environment variables:
- `AZURE_OPENAI_ENDPOINT` - API endpoint URL
- `AZURE_API_KEY` - Primary access key
- `GPT41_DEPLOYMENT_NAME` - gpt-4.1 deployment name
- `GPT41_MINI_DEPLOYMENT_NAME` - gpt-4.1-mini deployment name
- `GPT4O_DEPLOYMENT_NAME` - gpt-4o deployment name
- `FLUX_DEPLOYMENT_NAME` - FLUX-1.1-pro deployment name
- `DEEPSEEK_DEPLOYMENT_NAME` - DeepSeek-V3.1 deployment name

## Configuration

### Parameter File Structure

```json
{
  "parameters": {
    "location": { "value": "eastus2" },
    "openAIAccountName": { "value": "my-unique-name" },
    "aiFoundryProjectName": { "value": "optional-project-tag" },
    "gpt41ModelName": { "value": "gpt-4.1" },
    "gpt41ModelVersion": { "value": "0409" },
    "gpt41CapacityTPM": { "value": 50 },
    // ... 15 more model parameters (3 per model × 5 models)
  }
}
```

### Supported Regions

Check region availability:
```bash
az account list-locations \
  --query "[?metadata.regionCategory=='Recommended'].name" \
  -o tsv
```

**Recommended**: `eastus2`, `westus3`, `swedencentral`

### TPM Quota Management

**Default allocation** (260 TPM total):
- GPT-4.1: 50 TPM
- GPT-4.1-Mini: 100 TPM (higher for high-volume queries)
- GPT-4o: 50 TPM
- FLUX-1.1-pro: 10 TPM (image generation is slower)
- DeepSeek-V3.1: 50 TPM

**Check current quota**:
```bash
az cognitiveservices account list-skus \
  --resource-group <your-rg> \
  --name <your-account> \
  --query "value[].capacity"
```

**To adjust**: Edit `*CapacityTPM` values in parameters file

## Docker Integration

### Update LiteLLM Configuration

```bash
# Source environment variables
source .env.azure-openai

# Update docker/litellm/config.yaml to reference:
#  - api_base: $AZURE_OPENAI_ENDPOINT (same for all 5 models)
#  - api_key: os.environ/AZURE_API_KEY
#  - model names: $GPT41_DEPLOYMENT_NAME, etc.

# Restart containers
docker compose restart litellm
```

See [quickstart.md](../specs/003-create-a-minimal/quickstart.md) for full integration scenarios.

## Troubleshooting

### Issue: "AccountNameAlreadyExists"
**Cause**: OpenAI account name not globally unique
**Fix**: Change `openAIAccountName` in parameters to a unique value

### Issue: "QuotaExceeded"
**Cause**: Subscription TPM quota limit reached (260 TPM exceeds limit)
**Fix**:
1. Reduce TPM capacities in parameters file, OR
2. Request quota increase: Azure Portal → Quotas → Cognitive Services

### Issue: "InvalidTemplate" during deployment
**Cause**: Bicep syntax error or API version incompatibility
**Fix**:
```bash
./scripts/validate.sh  # Should catch syntax errors
az bicep upgrade        # Upgrade Bicep CLI
```

### Issue: "Unauthorized" when deploying
**Cause**: Not logged into Azure CLI or insufficient permissions
**Fix**:
```bash
az login
az account set --subscription "<your-subscription-id>"
az role assignment list --assignee $(az account show --query user.name -o tsv)
# Verify you have "Contributor" role on resource group
```

### Issue: Docker can't connect to Azure
**Cause**: API key not set in environment
**Fix**:
```bash
source .env.azure-openai
docker compose restart litellm
```

### Issue: Model deployment failed
**Cause**: Model/version not available in region
**Fix**: Check regional availability:
```bash
az cognitiveservices account list-models \
  --resource-group <your-rg> \
  --name <your-account> \
  --query "[].{Name:name, Version:version}"
```

## Advanced Usage

### Idempotent Redeployment (Update Capacity)

```bash
# Edit TPM capacities in main.parameters.local.json
# Redeploy (updates in-place, no resource recreation)
./scripts/deploy.sh my-openai-rg @infra/main.parameters.local.json
```

Same endpoint and API key maintained.

### Dry-Run (What-If)

```bash
az deployment group what-if \
  --resource-group my-openai-rg \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.local.json
```

### Delete Infrastructure

```bash
# Delete resource group (removes all resources)
az group delete --name my-openai-rg --yes

# OR delete only OpenAI account (keep resource group)
az cognitiveservices account delete \
  --resource-group my-openai-rg \
  --name <account-name>
```

## Validation & Testing

**Syntax validation**:
```bash
./tests/bicep/linter.test.sh
```

**Build validation**:
```bash
./tests/bicep/build.test.sh
```

**Parameter validation**:
```bash
./tests/bicep/parameter-validation.test.sh
```

**Full validation suite**:
```bash
./scripts/validate.sh
```

**Integration tests**: See [quickstart.md](../specs/003-create-a-minimal/quickstart.md) for 6 end-to-end scenarios

## Migration from Old Infrastructure

See [specs/003-create-a-minimal/quickstart.md Scenario 3](../specs/003-create-a-minimal/quickstart.md#scenario-3-migration-from-old-infrastructure) for complete migration guide.

**Quick summary**:
1. Old infrastructure archived to `infra-archive/2025-10-12-original/`
2. Deploy new minimal Bicep to NEW resource group
3. Test Docker connectivity with new endpoint
4. Update production config
5. Manually delete old Azure resources

## Architecture

```
┌─────────────────────────────────────┐
│  Azure Resource Group               │
│  ┌────────────────────────────────┐ │
│  │ OpenAI Account (S0)            │ │
│  │  - endpoint: https://...       │ │
│  │  - apiKey: (via listKeys())    │ │
│  │                                │ │
│  │  ┌──────────────────────────┐  │ │
│  │  │ Model Deployments (5)    │  │ │
│  │  │  1. gpt-4.1       50 TPM │  │ │
│  │  │  2. gpt-4.1-mini 100 TPM │  │ │
│  │  │  3. gpt-4o        50 TPM │  │ │
│  │  │  4. FLUX-1.1-pro  10 TPM │  │ │
│  │  │  5. DeepSeek-V3.1 50 TPM │  │ │
│  │  │  Total: 260 TPM          │  │ │
│  │  └──────────────────────────┘  │ │
│  └────────────────────────────────┘ │
└─────────────────────────────────────┘
            │
            │ outputs → .env.azure-openai
            ▼
┌─────────────────────────────────────┐
│  Docker Compose Stack               │
│  ┌────────────────┐  ┌────────────┐ │
│  │ LiteLLM Proxy  │  │ Open WebUI │ │
│  │ (5 models)     │──│            │ │
│  └────────────────┘  └────────────┘ │
└─────────────────────────────────────┘
```

## File Structure

```
infra/
├── main.bicep              # Single-file Bicep (214 lines)
├── main.parameters.json    # Default parameters (all 5 models)
└── README.md               # This file

scripts/
├── deploy.sh               # Deployment automation (42 lines)
├── validate.sh             # Pre-deployment validation (22 lines)
└── outputs.sh              # Output extraction (52 lines)

tests/bicep/
├── linter.test.sh          # Syntax validation
├── build.test.sh           # Compilation test
├── parameter-validation.test.sh # Schema validation
└── deployment.test.sh      # Integration test

infra-archive/
└── 2025-10-12-original/    # Old 15-file infrastructure
```

## Links

- **Feature Spec**: [specs/003-create-a-minimal/spec.md](../specs/003-create-a-minimal/spec.md)
- **Quickstart Guide**: [specs/003-create-a-minimal/quickstart.md](../specs/003-create-a-minimal/quickstart.md)
- **Data Model**: [specs/003-create-a-minimal/data-model.md](../specs/003-create-a-minimal/data-model.md)
- **Contract Schemas**: [specs/003-create-a-minimal/contracts/](../specs/003-create-a-minimal/contracts/)
- **Azure OpenAI Docs**: https://learn.microsoft.com/azure/ai-services/openai/
- **Bicep Docs**: https://learn.microsoft.com/azure/azure-resource-manager/bicep/

---
Available models in EastUS2
Name                          Version
----------------------------  ----------------
gpt-35-turbo                  0613
gpt-35-turbo                  1106
gpt-35-turbo                  0125
gpt-35-turbo-16k              0613
gpt-4                         0125-Preview
gpt-4                         1106-Preview
gpt-4                         0613
gpt-4-32k                     0613
gpt-4                         turbo-2024-04-09
gpt-4o                        2024-05-13
gpt-4o                        2024-08-06
gpt-4o-mini                   2024-07-18
gpt-4o                        2024-11-20
gpt-4o-mini-realtime-preview  2024-12-17
gpt-4o-realtime-preview       2024-12-17
gpt-4o-realtime-preview       2025-06-03
gpt-4o-audio-preview          2024-12-17
gpt-4o-mini-audio-preview     2024-12-17
gpt-4o-transcribe             2025-03-20
gpt-4o-mini-transcribe        2025-03-20
gpt-4o-mini-tts               2025-03-20
gpt-4.1                       2025-04-14
gpt-4.1-mini                  2025-04-14
gpt-4.1-nano                  2025-04-14
gpt-5-mini                    2025-08-07
gpt-5-nano                    2025-08-07
gpt-5-chat                    2025-08-07
gpt-audio                     2025-08-28


**Constitutional Compliance**: v1.0.0 | **Feature**: 003-create-a-minimal | **Status**: ✅ Implemented
