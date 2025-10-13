# Quickstart: Minimal Single-File Bicep for OpenAI Provisioning

**Feature**: 003-create-a-minimal
**Date**: 2025-10-12
**Audience**: DevOps engineers deploying Azure OpenAI for Docker-based LiteLLM

## Overview
This quickstart validates the complete workflow from Bicep deployment through Docker integration. Follow these scenarios to verify the minimal infrastructure deployment works end-to-end.

---

## Prerequisites

- **Azure CLI** 2.50+ installed and authenticated
- **Bicep CLI** 0.18+ installed (`az bicep install`)
- **Docker** + **Docker Compose** installed
- **Azure subscription** with OpenAI service enabled
- **Azure Resource Group** created (or permission to create one)
- **Existing AI Foundry project** (optional, for organizational linking)

**Verification**:
```bash
az --version | grep "azure-cli"
az bicep version
docker --version
docker compose version
az account show --query "name" -o tsv  # Should show your subscription name
```

---

## Scenario 1: Fresh Deployment (No Existing OpenAI Resources)

**Goal**: Deploy minimal Bicep from scratch and verify outputs

**Steps**:

### 1.1 Prepare Parameters
```bash
cd /home/greg/dev/az-llm
cp infra/main.parameters.json infra/main.parameters.local.json

# Edit main.parameters.local.json:
# - Set "openAIAccountName" to a globally unique name (e.g., "yourinitials-llm-dev")
# - Set "location" to your preferred region (e.g., "eastus2", "westus3")
# - Adjust TPM quotas if needed (default: gpt=50, flux=10)
```

### 1.2 Validate Bicep Syntax
```bash
./tests/bicep/linter.test.sh
# Expected: ✅ Syntax valid

./tests/bicep/build.test.sh
# Expected: ✅ Build successful
```

### 1.3 Dry-Run Deployment (What-If)
```bash
az deployment group what-if \
  --resource-group <your-resource-group> \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.local.json

# Expected: Shows resources to be created (OpenAI account + 2 deployments)
```

### 1.4 Execute Deployment
```bash
./scripts/deploy.sh <your-resource-group> @infra/main.parameters.local.json

# Expected output:
# ✅ Deployment complete
# ✅ Outputs extracted
# Endpoint: https://<your-account>.openai.azure.com/
# API Key: <redacted>
# Deployments: gpt-4.1, FLUX-1.1-pro
```

**Time**: ~5-7 minutes

### 1.5 Verify Outputs
```bash
./scripts/outputs.sh <your-resource-group>

# Expected: .env.azure-openai file created with:
# AZURE_OPENAI_ENDPOINT=https://<your-account>.openai.azure.com/
# AZURE_API_KEY=<32-char-key>
# GPT41_DEPLOYMENT_NAME=gpt-4.1
# GPT41_MINI_DEPLOYMENT_NAME=gpt-4.1-mini
# GPT4O_DEPLOYMENT_NAME=gpt-4o
# FLUX_DEPLOYMENT_NAME=FLUX-1.1-pro
# DEEPSEEK_DEPLOYMENT_NAME=DeepSeek-V3.1
```

### 1.6 Update Docker Configuration
```bash
# Backup existing config
cp docker/litellm/config.yaml docker/litellm/config.yaml.backup

# Update api_base and deployment names in config.yaml:
# - model_name: gpt-4.1 → api_base: <AZURE_OPENAI_ENDPOINT>
# - model_name: FLUX-1.1-pro → api_base: <AZURE_OPENAI_ENDPOINT>

# Set environment variable
export AZURE_API_KEY=$(grep AZURE_API_KEY .env.azure-openai | cut -d= -f2)
```

### 1.7 Test Docker Connectivity
```bash
docker compose up -d litellm

# Wait 10 seconds for startup
sleep 10

# Test GPT endpoint
curl -X POST http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4.1",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'

# Expected: JSON response with "choices" array
```

**Acceptance**: ✅ Deployment succeeded, outputs extracted, Docker can reach Azure OpenAI

---

## Scenario 2: Update Model Capacity (Idempotent Redeployment)

**Goal**: Modify TPM quotas without recreating resources

**Steps**:

### 2.1 Modify Parameters
```bash
# Edit infra/main.parameters.local.json:
# - Change "gptCapacityTPM" from 50 to 100

# Verify change
grep gptCapacityTPM infra/main.parameters.local.json
```

### 2.2 Redeploy (Should Update, Not Recreate)
```bash
./scripts/deploy.sh <your-resource-group> @infra/main.parameters.local.json

# Expected:
# ✅ Deployment complete (faster than initial, ~2-3 minutes)
# ✅ No resource recreation (same endpoint, same API key)
```

### 2.3 Verify No Downtime
```bash
# API key should be unchanged
./scripts/outputs.sh <your-resource-group>
diff .env.azure-openai .env.azure-openai.previous

# Expected: Only timestamps differ, endpoint/key identical
```

**Acceptance**: ✅ Capacity updated in-place, no endpoint/key changes, Docker connectivity unaffected

---

## Scenario 3: Migration from Old Infrastructure

**Goal**: Replace old 15-file Bicep with minimal version

**Steps**:

### 3.1 Archive Old Infrastructure
```bash
# Create archive directory
mkdir -p infra-archive/2025-10-12-original

# Move old Bicep files (excluding new minimal files)
mv infra/modules infra-archive/2025-10-12-original/
mv infra/environments infra-archive/2025-10-12-original/
mv infra/bicepconfig.json infra-archive/2025-10-12-original/
# (List continues for all old files)

# Verify new minimal files remain
ls infra/
# Expected: main.bicep, main.parameters.json, README.md only
```

### 3.2 Deploy Minimal Bicep to NEW Resource Group
```bash
# Create test resource group
az group create --name az-llm-minimal-test --location eastus2

# Deploy minimal infrastructure
./scripts/deploy.sh az-llm-minimal-test @infra/main.parameters.local.json
```

### 3.3 Parallel Test with Docker
```bash
# Update config.yaml with NEW endpoint (keep old as backup)
cp docker/litellm/config.yaml.backup docker/litellm/config.yaml.new-endpoint

# Test new endpoint
export AZURE_API_KEY=$(grep AZURE_API_KEY .env.azure-openai | cut -d= -f2)
docker compose restart litellm

# Verify connectivity (repeat Scenario 1.7 test)
```

### 3.4 Switch Production Configuration
```bash
# After successful test, update production config
cp docker/litellm/config.yaml.new-endpoint docker/litellm/config.yaml

# Restart all containers
docker compose down
docker compose up -d
```

### 3.5 Delete Old Azure Resources (Manual)
```bash
# List resources in old resource group
az resource list --resource-group <old-rg> --output table

# Manually delete via Azure Portal:
# - App Service Plan
# - App Service
# - Static Web App
# - Virtual Network
# - Log Analytics Workspace
# - Application Insights
# (Keep AI Foundry project if linking to new OpenAI account)

# OR delete entire old resource group (if no longer needed):
az group delete --name <old-rg> --yes --no-wait
```

**Acceptance**: ✅ Old files archived, new minimal infrastructure deployed, Docker connectivity verified, old Azure resources cleaned up

---

## Scenario 4: Quota Limit Failure Handling

**Goal**: Verify graceful failure when TPM quota exceeded

**Steps**:

### 4.1 Intentionally Exceed Quota
```bash
# Edit parameters to exceed subscription quota
# Example: Set gptCapacityTPM to 999999 (unrealistic value)

./scripts/deploy.sh <your-resource-group> @infra/main.parameters.local.json
```

### 4.2 Verify Failure Behavior
```bash
# Expected output:
# ❌ Deployment failed
# Error: QuotaExceeded
# Message: "The request cannot be fulfilled because the resource limit has been exceeded."
# Required action: Contact Azure support to increase quota or reduce capacity

# Verify rollback (no partial state)
az cognitiveservices account show --name <your-account> --resource-group <your-rg>
# Expected: Previous successful deployment state unchanged
```

### 4.3 Fix and Retry
```bash
# Reset parameters to valid quotas
# Redeploy
./scripts/deploy.sh <your-resource-group> @infra/main.parameters.local.json

# Expected: ✅ Deployment succeeds with corrected values
```

**Acceptance**: ✅ Deployment fails immediately with clear error, no partial resources created, retry succeeds

---

## Scenario 5: Multi-Model Deployment Verification

**Goal**: Verify all 5 models work (3 GPT variants + image + DeepSeek)

**Steps**:

### 5.1 Test GPT-4.1 (Primary)
```bash
curl -X POST http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4.1",
    "messages": [{"role": "user", "content": "Explain Azure in 10 words."}],
    "max_tokens": 20
  }' | jq '.choices[0].message.content'

# Expected: Text response from GPT-4.1
```

### 5.2 Test GPT-4.1-Mini (Cost-Effective)
```bash
curl -X POST http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4.1-mini",
    "messages": [{"role": "user", "content": "What is 2+2?"}],
    "max_tokens": 10
  }' | jq '.choices[0].message.content'

# Expected: "4" or similar short response
```

### 5.3 Test GPT-4o (High-Performance)
```bash
curl -X POST http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4o",
    "messages": [{"role": "user", "content": "Describe a sunset."}],
    "max_tokens": 30
  }' | jq '.choices[0].message.content'

# Expected: Descriptive text about sunset
```

### 5.4 Test FLUX-1.1-pro (Image Generation)
```bash
curl -X POST http://localhost:4000/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "model": "FLUX-1.1-pro",
    "prompt": "A minimal cloud architecture diagram",
    "n": 1,
    "size": "1024x1024"
  }' | jq '.data[0].url'

# Expected: URL to generated image
```

### 5.5 Test DeepSeek-V3.1 (Alternative LLM)
```bash
curl -X POST http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "DeepSeek-V3.1",
    "messages": [{"role": "user", "content": "What is the capital of France?"}],
    "max_tokens": 10
  }' | jq '.choices[0].message.content'

# Expected: "Paris" or similar response
```

### 5.6 Verify All Deployment Names
```bash
az cognitiveservices account deployment list \
  --name <your-account> \
  --resource-group <your-rg> \
  --query "[].name" -o tsv

# Expected output (5 lines):
# gpt-4.1
# gpt-4.1-mini
# gpt-4o
# FLUX-1.1-pro
# DeepSeek-V3.1
```

**Acceptance**: ✅ All 5 model types deployed, all accessible via LiteLLM, deployment names match outputs

---

## Scenario 6: End-to-End Open WebUI Integration

**Goal**: Verify full stack from Bicep → LiteLLM → Open WebUI

**Steps**:

### 6.1 Start Full Stack
```bash
docker compose up -d

# Wait for all services
docker compose ps
# Expected: litellm, open-webui, postgres all "Up"
```

### 6.2 Access Open WebUI
```bash
# Open browser: http://localhost:3000
# Login/register
# Navigate to model selection
```

### 6.3 Test Chat with GPT
```
User: "What is Azure OpenAI?"
Expected: Coherent response from gpt-4.1 model
```

### 6.4 Test Image Generation
```
User: "Generate an image: sunset over mountains"
Expected: Image generated via FLUX-1.1-pro
```

### 6.5 Verify Metrics (Optional)
```bash
# Check LiteLLM logs
docker compose logs litellm | grep "POST /chat/completions"

# Expected: Successful 200 responses
```

**Acceptance**: ✅ Open WebUI functional, chat works, image generation works, logs show successful Azure API calls

---

## Troubleshooting

### Issue: Deployment fails with "AccountNameAlreadyExists"
**Cause**: OpenAI account name not globally unique
**Fix**: Change `openAIAccountName` in parameters to a unique value

### Issue: "QuotaExceeded" error
**Cause**: Subscription TPM quota limit reached
**Fix**: Reduce `gptCapacityTPM` / `fluxCapacityTPM` or request quota increase via Azure support

### Issue: Docker can't connect to Azure endpoint
**Cause**: API key not set in environment
**Fix**: `export AZURE_API_KEY=$(grep AZURE_API_KEY .env.azure-openai | cut -d= -f2)`

### Issue: LiteLLM returns "Deployment not found"
**Cause**: Mismatch between `config.yaml` model names and deployed deployment names
**Fix**: Verify `./scripts/outputs.sh` deployment names match `config.yaml` model identifiers

### Issue: Bicep build fails with syntax errors
**Cause**: Bicep CLI version too old
**Fix**: `az bicep upgrade`

---

## Acceptance Criteria Summary

| Scenario | Expected Result | Validation |
|----------|-----------------|------------|
| 1 (Fresh Deploy) | 5 models deployed, outputs valid | ✅ Deployment succeeds, all 5 models listed, Docker connectivity |
| 2 (Update Capacity) | Idempotent update, no downtime | ✅ Same endpoint/key, capacity changed |
| 3 (Migration) | Old archived, new deployed, Docker working | ✅ Old files moved, new infra functional |
| 4 (Quota Failure) | Graceful failure, clear error message | ✅ Deployment fails immediately, rollback clean |
| 5 (Multi-Model) | All 5 models work (3 GPT + image + DeepSeek) | ✅ All 5 endpoints return valid responses |
| 6 (End-to-End) | Full stack functional with 5 models | ✅ Open WebUI chat (5 models) + image gen working |

**Overall Success Criteria**: All 6 scenarios pass with ✅ acceptance, 5 models operational

---

**Quickstart Status**: ✅ COMPLETE
**Next Step**: Generate tasks.md (via `/tasks` command)
