# Research: Minimal Single-File Bicep for OpenAI Provisioning

**Feature**: 003-create-a-minimal
**Date**: 2025-10-12
**Status**: Complete

## Purpose
Document technical decisions and research findings for replacing over-engineered 15-file Bicep infrastructure with minimal single-file approach for Azure OpenAI provisioning.

---

## Decision 1: Bicep Resource Type for Azure OpenAI

**Chosen**: `Microsoft.CognitiveServices/accounts@2023-05-01` with `kind: 'OpenAI'`

**Rationale**:
- Official Azure resource type for OpenAI Service
- Supports model deployments as child resources
- Stable API version (2023-05-01) widely documented
- Compatible with AI Foundry project linking via properties

**Alternatives Considered**:
- **Azure AI Services multi-service account**: Overly broad, includes speech/vision/etc. - violates simplicity
- **Azure Machine Learning workspace**: Wrong abstraction layer, designed for training not inference

**References**:
- [Bicep resource definition for Cognitive Services](https://learn.microsoft.com/azure/templates/microsoft.cognitiveservices/accounts)
- [Azure OpenAI Service documentation](https://learn.microsoft.com/azure/ai-services/openai/)

---

## Decision 2: AI Foundry Project Linking Mechanism

**Chosen**: Reference existing AI Foundry project via `properties.customSubDomainName` and resource tags

**Rationale**:
- AI Foundry projects are **container resources** created through Azure portal
- Bicep cannot directly "link" to AI Foundry - instead, OpenAI resources are **placed within** the same resource group
- Using consistent naming convention (`aiFoundryProjectId` tag) enables portal organization
- Custom subdomain ensures unique endpoint URL alignment

**Alternatives Considered**:
- **Bicep resource dependency**: AI Foundry projects aren't Bicep-manageable in the same way (portal-first workflow)
- **Hub connection object**: Overly complex for single-environment dev setup

**Implementation**:
```bicep
resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIAccountName
  location: location
  kind: 'OpenAI'
  sku: { name: 'S0' }
  properties: {
    customSubDomainName: customSubdomain
    publicNetworkAccess: 'Enabled'
    // No explicit AI Foundry reference needed - resource group placement suffices
  }
  tags: {
    aiFoundryProject: aiFoundryProjectName  // Organizational metadata
    deployedBy: 'bicep-minimal'
  }
}
```

**References**:
- [Azure AI Foundry documentation](https://learn.microsoft.com/azure/ai-studio/)
- Current project uses manually-created AI Foundry project `bg-llm-01`

---

## Decision 3: Model Deployment Strategy

**Chosen**: In-template model deployments as child resources with parameterized capacity (5 models)

**Rationale**:
- Bicep child resources (`Microsoft.CognitiveServices/accounts/deployments`) enable single-file approach
- Parameterized TPM quotas allow environment-specific tuning without code changes
- Idempotent redeployment updates model versions without recreation
- **5 models support diverse use cases**: primary GPT, cost-effective GPT, high-performance GPT, image gen, alternative LLM

**Alternatives Considered**:
- **Separate ARM template per model**: Violates NFR-001 (single file requirement)
- **Post-deployment az CLI commands**: Not infrastructure-as-code, violates idempotency (FR-012)

**Model Lineup**:
1. **gpt-4.1** - Primary GPT model (latest stable)
2. **gpt-4.1-mini** - Cost-effective GPT for simple queries
3. **gpt-4o** - High-performance multimodal GPT
4. **FLUX-1.1-pro** - Image generation model
5. **DeepSeek-V3.1** - Alternative LLM for specialized tasks

**Implementation Pattern** (repeated for each model):
```bicep
resource gpt41Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAIAccount
  name: 'gpt-4.1'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4.1'
      version: '0409'
    }
  }
  sku: {
    name: 'Standard'
    capacity: 50  // TPM quota
  }
}

resource gpt41MiniDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAIAccount
  name: 'gpt-4.1-mini'
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: '2024-07-18'
    }
  }
  sku: {
    name: 'Standard'
    capacity: 100  // Higher TPM for high-volume
  }
}

// ... (3 more deployments: gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1)
```

**References**:
- [Azure OpenAI model deployments](https://learn.microsoft.com/azure/ai-services/openai/how-to/create-resource)
- Current config.yaml uses `DeepSeek-V3.1`, `gpt-4.1`, and `FLUX-1.1-pro`

---

## Decision 4: API Key Retrieval Pattern

**Chosen**: Use `listKeys()` Bicep function in outputs section

**Rationale**:
- Built-in Bicep function securely retrieves keys without storing in template
- Returns keys only to deployment output (not template itself)
- Compatible with `az deployment group show --query properties.outputs` extraction

**Alternatives Considered**:
- **Azure Key Vault reference**: Overly complex for single-environment dev (violates Simplicity-First)
- **Managed identity**: Not supported by clarification decision (API key auth only)

**Implementation**:
```bicep
output endpoint string = openAIAccount.properties.endpoint
output apiKey string = openAIAccount.listKeys().key1
output deploymentNames array = [
  gpt41Deployment.name
  gpt41MiniDeployment.name
  gpt4oDeployment.name
  fluxDeployment.name
  deepseekDeployment.name
]
```

**Security Note**: Output values visible in deployment history. For production, use Key Vault references.

**References**:
- [Bicep listKeys function](https://learn.microsoft.com/azure/azure-resource-manager/bicep/bicep-functions-resource#listkeys)

---

## Decision 5: Parameter File Structure

**Chosen**: Single JSON parameters file with clear defaults and inline descriptions

**Rationale**:
- Satisfies FR-008 (single parameter file for one environment)
- JSON schema validation via `$schema` property enables IDE autocomplete
- Defaults in main.bicep minimize required overrides

**Alternatives Considered**:
- **Bicepparam files**: Newer format, less tooling support (violates "boring tech")
- **Environment variables**: Not infrastructure-as-code, hard to version control

**Implementation**:
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "location": { "value": "eastus2" },
    "openAIAccountName": { "value": "bg-llm-minimal" },
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

**References**:
- [Azure parameter files](https://learn.microsoft.com/azure/azure-resource-manager/bicep/parameter-files)

---

## Decision 6: Deployment Validation Approach

**Chosen**: Multi-layered bash test scripts (syntax → build → dry-run → integration)

**Rationale**:
- Satisfies TDD constitutional requirement (tests before implementation)
- Bash scripts executable in CI/CD (GitHub Actions, Azure DevOps)
- Layered approach enables fast feedback (syntax check in <5s, full deployment in ~5min)

**Test Layers**:
1. **Syntax validation** (`az bicep build --file main.bicep`) - FR-011
2. **Parameter schema validation** (JSON schema check against Bicep @description metadata)
3. **Dry-run deployment** (`--what-if` flag) - detect quota/permission issues pre-deploy
4. **Integration test** (full deploy → output extraction → Docker config update → connectivity test)

**Alternatives Considered**:
- **Pester tests** (PowerShell): Platform-specific, project uses bash/Linux
- **Manual testing**: Not automatable, violates TDD principle

**Implementation**:
```bash
# tests/bicep/linter.test.sh
az bicep build --file infra/main.bicep --stdout > /dev/null
if [ $? -eq 0 ]; then echo "✅ Syntax valid"; else echo "❌ Syntax errors"; exit 1; fi

# tests/bicep/build.test.sh
az bicep build --file infra/main.bicep --outfile /tmp/main.json
az deployment group validate --resource-group test-rg --template-file /tmp/main.json
```

**References**:
- [Bicep testing best practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices#testing)
- Project already has `tests/bicep/` directory structure

---

## Decision 7: Deployment Script Design

**Chosen**: Three-script pattern (deploy.sh, validate.sh, outputs.sh)

**Rationale**:
- **deploy.sh**: Single entry point satisfies NFR-002 (<5 commands)
- **validate.sh**: Pre-flight checks (Azure CLI installed, logged in, subscription set, resource group exists)
- **outputs.sh**: Post-deployment extraction to `.env` format for Docker integration

**Alternatives Considered**:
- **Makefile**: Less portable across Windows/WSL/Linux, additional dependency
- **Single mega-script**: Harder to test individual stages

**Implementation Flow**:
```bash
# scripts/deploy.sh
./scripts/validate.sh || exit 1
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file infra/main.bicep \
  --parameters @infra/main.parameters.json
./scripts/outputs.sh > .env.azure-openai
```

**References**:
- [Azure CLI deployment commands](https://learn.microsoft.com/cli/azure/deployment/group)

---

## Decision 8: Migration Path for Old Infrastructure

**Chosen**: Archive-first strategy (move `infra/` → `infra-archive/`, then manual Azure resource deletion)

**Rationale**:
- Aligns with clarification decision (archive Bicep files, delete Azure resources)
- Manual Azure deletion prevents accidental data loss (no automation for destructive operations)
- Git history preserves old structure even after archival

**Migration Steps**:
1. Create `infra-archive/` directory
2. Move existing `infra/` contents to `infra-archive/[date]-original/`
3. Deploy new minimal Bicep to **separate** resource group first (validate outputs)
4. Update `docker/litellm/config.yaml` with new endpoint/key
5. Test Docker connectivity
6. Manually delete old Azure resources via portal (App Service, VNet, Static Web App, etc.)
7. Update documentation

**Alternatives Considered**:
- **Terraform destroy**: Project doesn't use Terraform, would require state recreation
- **Automated deletion script**: Too risky for one-time migration

**References**:
- FR-014 (migration instructions requirement)

---

## Decision 9: Documentation Structure

**Chosen**: Single infra/README.md with deployment, output extraction, and troubleshooting sections

**Rationale**:
- Satisfies FR-017 (simplified README), FR-018 (output extraction docs), FR-019 (Docker relationship)
- NFR-003 (readable by Azure-unfamiliar developers) → step-by-step format with examples
- Single file easier to maintain than multiple docs

**Sections**:
1. **Prerequisites** (Azure CLI, Bicep CLI, Azure subscription)
2. **Quick Start** (3-command deployment)
3. **Configuration** (parameters.json explanation)
4. **Output Extraction** (how to get endpoint/key into .env)
5. **Docker Integration** (updating config.yaml)
6. **Troubleshooting** (quota errors, authentication issues)

**Alternatives Considered**:
- **Separate DEPLOYMENT.md + USAGE.md**: Violates simplicity, users jump between files
- **Inline comments only**: Not discoverable, violates FR-017

---

## Open Questions

None - all Technical Context items resolved. All clarifications answered in spec.md Session 2025-10-12.

**Model Count Update**: Changed from 2 models (gpt-4.1, FLUX-1.1-pro) to 5 models (gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1) to match current config.yaml and provide diverse model options.

---

## Integration Points Summary

| System | Integration Method | Contract |
|--------|-------------------|----------|
| Azure OpenAI | Bicep resource provisioning | `Microsoft.CognitiveServices/accounts` API |
| AI Foundry | Resource group placement + tags | Organizational metadata |
| Docker Compose | .env file with endpoint + key | Environment variables |
| LiteLLM | config.yaml `api_base` + `api_key` | YAML configuration |
| Azure CLI | Deployment commands | `az deployment group` subcommands |

---

**Research Phase Status**: ✅ COMPLETE
**Next Step**: Phase 1 (Design & Contracts)
