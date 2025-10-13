# Data Model: Minimal Single-File Bicep for OpenAI Provisioning

**Feature**: 003-create-a-minimal
**Date**: 2025-10-12
**Domain**: Infrastructure-as-Code

## Overview
This data model describes the infrastructure entities and their relationships for provisioning Azure OpenAI resources via Bicep. Note: This is **infrastructure metadata**, not application data.

---

## Entities

### 1. OpenAI Account
**Description**: Azure Cognitive Services account configured for OpenAI workloads

**Attributes**:
| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| `name` | string | Yes | 2-64 chars, alphanumeric + hyphens | Globally unique account name |
| `location` | string | Yes | Valid Azure region | Deployment region (e.g., `eastus2`) |
| `kind` | string | Yes | Must be `'OpenAI'` | Resource subtype |
| `sku.name` | string | Yes | Must be `'S0'` | Standard pricing tier |
| `customSubDomainName` | string | Yes | Same as `name` | Unique subdomain for endpoint URL |
| `publicNetworkAccess` | string | Yes | `'Enabled'` or `'Disabled'` | Network accessibility |
| `aiFoundryProject` | string (tag) | No | Free-form | AI Foundry project name for organization |

**Relationships**:
- **Has many** Model Deployments (child resources)
- **Belongs to** Azure Resource Group
- **Associated with** AI Foundry Project (via resource group placement)

**State Transitions**:
```
[Not Exists] --deploy--> [Provisioning] --success--> [Succeeded] <--update--> [Succeeded]
                              |
                              +--failure--> [Failed]
```

**Bicep Resource Type**: `Microsoft.CognitiveServices/accounts@2023-05-01`

---

### 2. Model Deployment
**Description**: Specific AI model version deployed within an OpenAI account

**Attributes**:
| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| `name` | string | Yes | 2-64 chars, alphanumeric + hyphens | Deployment identifier |
| `model.format` | string | Yes | Must be `'OpenAI'` | Model format specification |
| `model.name` | string | Yes | Valid OpenAI model name | Model identifier (e.g., `gpt-4.1`, `FLUX-1.1-pro`) |
| `model.version` | string | Yes | Model version string | Version identifier (e.g., `0409`, `2024-11-04`) |
| `sku.name` | string | Yes | Must be `'Standard'` | Deployment tier |
| `sku.capacity` | integer | Yes | 1-1000 | Tokens-per-minute (TPM) quota allocation |

**Relationships**:
- **Belongs to** OpenAI Account (parent resource)
- **Referenced by** LiteLLM config.yaml (via deployment name)

**State Transitions**:
```
[Not Exists] --deploy--> [Creating] --success--> [Succeeded] <--update capacity--> [Succeeded]
                             |
                             +--quota exceeded--> [Failed]
```

**Bicep Resource Type**: `Microsoft.CognitiveServices/accounts/deployments@2023-05-01`

---

### 3. Deployment Parameters
**Description**: Configuration inputs for Bicep template execution (5 model deployments)

**Attributes**:
| Field | Type | Required | Default | Validation | Description |
|-------|------|----------|---------|------------|-------------|
| `location` | string | Yes | (none) | Valid Azure region | Deployment region |
| `openAIAccountName` | string | Yes | (none) | 2-64 chars, globally unique | OpenAI account name |
| `aiFoundryProjectName` | string | No | `''` | Free-form | AI Foundry project tag value |
| **GPT-4.1 (Primary)** |
| `gpt41ModelName` | string | Yes | `'gpt-4.1'` | Valid GPT model | Primary GPT model |
| `gpt41ModelVersion` | string | Yes | `'0409'` | Version string | GPT-4.1 version |
| `gpt41CapacityTPM` | integer | Yes | `50` | 1-1000 | GPT-4.1 TPM quota |
| **GPT-4.1-Mini (Cost-Effective)** |
| `gpt41MiniModelName` | string | Yes | `'gpt-4o-mini'` | Valid GPT model | Mini GPT model |
| `gpt41MiniModelVersion` | string | Yes | `'2024-07-18'` | Version string | Mini version |
| `gpt41MiniCapacityTPM` | integer | Yes | `100` | 1-1000 | Mini TPM quota |
| **GPT-4o (High-Performance)** |
| `gpt4oModelName` | string | Yes | `'gpt-4o'` | Valid GPT model | GPT-4o model |
| `gpt4oModelVersion` | string | Yes | `'2024-08-06'` | Version string | GPT-4o version |
| `gpt4oCapacityTPM` | integer | Yes | `50` | 1-1000 | GPT-4o TPM quota |
| **FLUX-1.1-pro (Image Generation)** |
| `fluxModelName` | string | Yes | `'FLUX-1.1-pro'` | Valid image model | Image generation model |
| `fluxModelVersion` | string | Yes | `'2024-11-04'` | Version string | FLUX version |
| `fluxCapacityTPM` | integer | Yes | `10` | 1-1000 | FLUX TPM quota |
| **DeepSeek-V3.1 (Alternative LLM)** |
| `deepseekModelName` | string | Yes | `'DeepSeek-V3.1'` | Valid model | DeepSeek model |
| `deepseekModelVersion` | string | Yes | `'2024-05-01'` | Version string | DeepSeek version |
| `deepseekCapacityTPM` | integer | Yes | `50` | 1-1000 | DeepSeek TPM quota |

**Relationships**:
- **Input to** Bicep Template Deployment
- **Defines** OpenAI Account configuration
- **Defines** 5 Model Deployment specifications

**Validation Rules**:
- `openAIAccountName` must be globally unique across Azure
- Sum of all TPM capacities must not exceed subscription quota (default total: 260 TPM)
- `location` must support all 5 specified model types

**Storage Format**: JSON (Azure Resource Manager parameters file)

---

### 4. Deployment Outputs
**Description**: Values returned after successful Bicep deployment (5 models)

**Attributes**:
| Field | Type | Cardinality | Description |
|-------|------|-------------|-------------|
| `endpoint` | string (URL) | 1 | OpenAI API endpoint (e.g., `https://bg-llm-minimal.openai.azure.com/`) |
| `apiKey` | string (secret) | 1 | Primary access key from `listKeys()` |
| `resourceId` | string | 1 | Azure resource ID for RBAC/monitoring |
| `deploymentNames` | array[string] | 5 | List of 5 model deployment names [gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1] |
| `location` | string | 1 | Deployed region (echo of input) |

**Relationships**:
- **Output from** Bicep Template Deployment
- **Input to** Docker Environment Configuration (.env file)
- **Input to** LiteLLM config.yaml (api_base, api_key)

**Validation Rules**:
- `endpoint` must be HTTPS URL
- `apiKey` must be 32+ character string
- `deploymentNames` must contain exactly 5 entries (3 GPT variants + image model + DeepSeek)

**Storage Format**: JSON (Azure deployment outputs)

---

### 5. LiteLLM Configuration
**Description**: Docker service configuration for LiteLLM proxy

**Attributes**:
| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| `model_name` | string | Yes | Free-form | Friendly name for model |
| `model` | string | Yes | Format: `azure/{deployment}` | LiteLLM model identifier |
| `api_base` | string | Yes | HTTPS URL | OpenAI endpoint from outputs |
| `api_version` | string | Yes | YYYY-MM-DD format | Azure API version |
| `api_key` | string | Yes | `os.environ/VAR_NAME` | Environment variable reference |
| `timeout` | integer | No | Seconds | Request timeout |

**Relationships**:
- **Consumes** Deployment Outputs (endpoint, apiKey, deploymentNames)
- **Consumed by** LiteLLM Docker container
- **Consumed by** Open WebUI Docker container (via LiteLLM proxy)

**Validation Rules**:
- `api_base` must match `endpoint` output from deployment
- `model` deployment name must exist in `deploymentNames` output
- `api_key` environment variable must be set before container start

**Storage Format**: YAML (docker/litellm/config.yaml)

---

## Entity Relationships Diagram

```
┌─────────────────────────────────────────────────────────┐
│   Azure Resource Group                                  │
│  ┌───────────────────────────────────────────────────┐  │
│  │  OpenAI Account                                   │  │
│  │  - name                                           │  │
│  │  - location                                       │  │
│  │  - endpoint (computed)                            │  │
│  │  - apiKey (via listKeys())                        │  │
│  │                                                   │  │
│  │  ┌─────────────────────────────────────────────┐  │  │
│  │  │ Model Deployments (5 total)                 │  │  │
│  │  │                                             │  │  │
│  │  │ 1. gpt-4.1           - capacity: 50 TPM    │  │  │
│  │  │ 2. gpt-4.1-mini      - capacity: 100 TPM   │  │  │
│  │  │ 3. gpt-4o            - capacity: 50 TPM    │  │  │
│  │  │ 4. FLUX-1.1-pro      - capacity: 10 TPM    │  │  │
│  │  │ 5. DeepSeek-V3.1     - capacity: 50 TPM    │  │  │
│  │  │                                             │  │  │
│  │  │ Total TPM: 260                              │  │  │
│  │  └─────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────┘  │
│          │                                              │
│          │ (placed in same RG)                          │
│          ▼                                              │
│  ┌───────────────────────────────────────────────────┐  │
│  │  AI Foundry Project (manually created)           │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
            │
            │ outputs (endpoint, apiKey, 5 deploymentNames)
            ▼
    ┌──────────────────────────────────────┐
    │  Deployment Outputs (JSON)           │
    │  - deploymentNames: [5 models]       │
    └──────────────────────────────────────┘
            │
            │ extracted to .env
            ▼
    ┌──────────────────────────────────────┐
    │  LiteLLM config.yaml                 │
    │  (Docker configuration - 5 models)   │
    └──────────────────────────────────────┘
```

---

## Validation Rules Summary

### Cross-Entity Constraints
1. **Unique Naming**: `openAIAccountName` must be globally unique (enforced by Azure)
2. **Quota Limits**: Sum(`*.capacityTPM`) ≤ Subscription Quota (enforced by Azure)
3. **Region Support**: All model types must be available in `location` (enforced by Azure)
4. **Deployment Names Match**: `config.yaml` model references must exist in `deploymentNames` output
5. **API Version Compatibility**: `config.yaml` `api_version` must match deployed API version

### Data Consistency Rules
1. **Endpoint Format**: Deployment outputs `endpoint` must be HTTPS with Azure domain
2. **API Key Security**: `apiKey` output must never be committed to git (use .env, .gitignore)
3. **Idempotency**: Redeployment with same parameters must not recreate resources (update in-place)

---

## State Management

### Resource Lifecycle
```
1. Template Definition (main.bicep)
       ↓
2. Parameter Input (main.parameters.json)
       ↓
3. Deployment Execution (az deployment group create)
       ↓
4. Resource Provisioning (Azure Resource Manager)
       ↓
5. Output Extraction (az deployment group show)
       ↓
6. Configuration Update (config.yaml + .env)
       ↓
7. Docker Container Start (docker compose up)
```

### Failure Handling
- **Quota Exceeded**: Deployment fails immediately (FR-013a), manual quota increase required
- **Invalid Parameters**: Deployment validation fails pre-execution
- **Partial Failure**: Azure Resource Manager rolls back entire deployment transaction
- **Network Timeout**: Deployment retries automatically (Azure SDK behavior)

---

## Migration Considerations

### Data Preserved
- **OpenAI account name**: Can reuse existing name if account deleted
- **Model deployments**: New deployments created (old ones deleted with old account)
- **API keys**: New keys generated (old keys become invalid)

### Data Discarded
- **Old VNet**: Deleted (no longer needed for Docker-only deployment)
- **Old App Service**: Deleted (no backend API in Docker setup)
- **Old Static Web App**: Deleted (Open WebUI runs in Docker)

### Migration Path
1. Deploy new minimal Bicep to **new resource group** (parallel deployment)
2. Extract new endpoint + key
3. Test Docker connectivity with new values
4. Switch production .env to new values
5. Archive old Bicep files
6. Delete old Azure resources (manual portal operation)

---

**Data Model Status**: ✅ COMPLETE
**Constitutional Compliance**: Clear Contracts principle satisfied (input/output schemas defined)
**Next Step**: Generate contract schemas (JSON Schema for parameters/outputs)
