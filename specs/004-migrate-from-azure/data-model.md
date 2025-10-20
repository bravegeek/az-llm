# Data Model: Azure AI Foundry Migration

**Feature**: 004-migrate-from-azure
**Date**: 2025-10-19
**Version**: 1.0.0

## Entity Relationship Diagram

```
┌─────────────────────────┐
│   AI Foundry Hub        │
│  (ML Workspace)         │
│                         │
│ - name: string          │
│ - location: string      │
│ - sku: object           │
│ - identity: object      │
└────────────┬────────────┘
             │ 1
             │ owns
             │ 0..*
┌────────────▼────────────┐
│   AI Foundry Project    │
│  (ML Workspace)         │
│                         │
│ - name: string          │
│ - hubResourceId: string │
│ - location: string      │
└────────────┬────────────┘
             │ 1
             │ contains
             │ 1
┌────────────▼────────────┐
│   AI Services           │
│  (Cognitive Services)   │
│                         │
│ - name: string          │
│ - kind: 'AIServices'    │
│ - sku: object           │
└────────────┬────────────┘
             │ 1
             │ hosts
             │ 5
┌────────────▼────────────┐
│   Model Deployment      │
│  (AI Services Deploy)   │
│                         │
│ - name: string          │
│ - model: object         │
│ - sku: object           │
└─────────────────────────┘
```

## Entities

### 1. AI Foundry Hub

**Type**: Azure ML Services Workspace (kind: 'Hub')

**Purpose**: Top-level container providing centralized resource management, identity, and networking for AI projects.

**Properties**:

| Property | Type | Required | Validation | Description |
|----------|------|----------|------------|-------------|
| name | string | Yes | 3-33 chars, alphanumeric + hyphens, globally unique | Hub resource name |
| location | string | Yes | Valid Azure region | Azure region for deployment |
| kind | string | Yes | Must be 'Hub' | Resource specialization type |
| sku.name | string | Yes | 'Basic' | Pricing tier |
| identity.type | string | Yes | 'SystemAssigned' | Managed identity type |
| properties.friendlyName | string | No | Max 255 chars | Display name |
| properties.description | string | No | Max 1000 chars | Hub description |

**Relationships**:
- **Parent**: None (top-level resource)
- **Children**: 1+ AI Foundry Projects

**Lifecycle**:
- Created before any projects
- Cannot be deleted while projects exist
- Soft delete enabled (48-hour recovery window)

**Validation Rules**:
- Name must be globally unique across Azure
- Location must support AI Foundry Hub resources
- Cannot change kind after creation

---

### 2. AI Foundry Project

**Type**: Azure ML Services Workspace (kind: 'Project')

**Purpose**: Scoped workspace within a hub for model deployments, compute resources, and project-specific configuration.

**Properties**:

| Property | Type | Required | Validation | Description |
|----------|------|----------|------------|-------------|
| name | string | Yes | 3-33 chars, alphanumeric + hyphens, unique in subscription | Project resource name |
| location | string | Yes | Must match Hub location | Azure region |
| kind | string | Yes | Must be 'Project' | Resource specialization type |
| identity.type | string | Yes | 'SystemAssigned' | Managed identity type |
| properties.hubResourceId | string | Yes | Valid Hub resource ID | Parent Hub reference |
| properties.friendlyName | string | No | Max 255 chars | Display name |
| properties.description | string | No | Max 1000 chars | Project description |

**Relationships**:
- **Parent**: 1 AI Foundry Hub (required)
- **Children**: 1 AI Services resource (for model deployments)

**Lifecycle**:
- Created after Hub exists
- Requires valid hubResourceId
- Deleted before Hub can be deleted
- Soft delete enabled

**Validation Rules**:
- Location must match Hub location
- Hub must exist before project creation
- hubResourceId must be valid Azure resource ID

---

### 3. AI Services Resource

**Type**: Azure Cognitive Services Account (kind: 'AIServices')

**Purpose**: Unified endpoint for deploying and accessing multiple AI models within an AI Foundry project.

**Properties**:

| Property | Type | Required | Validation | Description |
|----------|------|----------|------------|-------------|
| name | string | Yes | 2-64 chars, alphanumeric + hyphens, globally unique | AI Services account name |
| location | string | Yes | Valid Azure region | Azure region |
| kind | string | Yes | Must be 'AIServices' | Multi-service resource type |
| sku.name | string | Yes | 'S0' (Standard) | Pricing tier |
| properties.customSubDomainName | string | Yes | Same as name, unique | Custom subdomain for endpoint |

**Relationships**:
- **Parent**: 1 AI Foundry Project (implicit via resource group)
- **Children**: 5 Model Deployments

**Lifecycle**:
- Created within project's resource group
- Hosts multiple model deployments
- Cannot be deleted while deployments exist

**Validation Rules**:
- Custom subdomain must be globally unique
- Kind must be 'AIServices' (not 'OpenAI')
- SKU must support model deployments

**Endpoint Format**:
- Pattern: `https://{name}.{location}.inference.ml.azure.com/`
- Example: `https://bg-llm-ai.eastus2.inference.ml.azure.com/`

---

### 4. Model Deployment

**Type**: Azure Cognitive Services Deployment (child of AI Services)

**Purpose**: Individual AI model instance with allocated TPM capacity, version, and inference endpoint.

**Properties**:

| Property | Type | Required | Validation | Description |
|----------|------|----------|------------|-------------|
| name | string | Yes | Unique within parent, alphanumeric + hyphens | Deployment name |
| properties.model.format | string | Yes | Must be 'OpenAI' | API compatibility format |
| properties.model.name | string | Yes | Valid model name in catalog | Model identifier |
| properties.model.version | string | Yes | Valid version for model | Model version |
| sku.name | string | Yes | 'Standard' | Deployment tier |
| sku.capacity | integer | Yes | 1-1000 (TPM) | Tokens per minute capacity |

**5 Deployment Instances**:

| Deployment | Model Name | Model Version | Capacity (TPM) |
|------------|------------|---------------|----------------|
| gpt-41-deployment | gpt-4.1 | 2025-04-14 | 50 |
| gpt-41-mini-deployment | gpt-4o-mini | 2024-07-18 | 100 |
| gpt-4o-deployment | gpt-4o | 2024-08-06 | 50 |
| flux-deployment | FLUX-1.1-pro | latest | 10 |
| deepseek-deployment | DeepSeek-V3.1 | latest | 50 |

**Relationships**:
- **Parent**: 1 AI Services Resource (required)
- **Children**: None

**Lifecycle**:
- Created after AI Services resource exists
- Can be created/deleted independently
- Deployment name unique within AI Services resource

**Validation Rules**:
- Model must be available in region (pre-deployment check)
- Capacity must not exceed subscription quota
- Model version must be valid for model name
- Total capacity across deployments: 260 TPM

**Endpoint Format**:
- Inherited from parent AI Services endpoint
- Accessed via deployment name in API calls
- Example: `https://{aiservices-name}.{location}.inference.ml.azure.com/openai/deployments/{deployment-name}/...`

---

### 5. Deployment Parameters

**Type**: Configuration input (main.parameters.json)

**Purpose**: Input configuration for Bicep template deployment.

**Properties**:

| Parameter | Type | Required | Default | Validation | Description |
|-----------|------|----------|---------|------------|-------------|
| location | string | Yes | - | Valid Azure region | Deployment region |
| hubName | string | Yes | - | 3-33 chars, globally unique | Hub name |
| projectName | string | Yes | - | 3-33 chars, subscription unique | Project name |
| aiServicesName | string | Yes | - | 2-64 chars, globally unique | AI Services account name |
| gpt41ModelName | string | No | 'gpt-4.1' | Valid model name | GPT-4.1 model identifier |
| gpt41ModelVersion | string | No | '2025-04-14' | Valid version | GPT-4.1 version |
| gpt41CapacityTPM | integer | No | 50 | 1-1000 | GPT-4.1 TPM capacity |
| gpt41MiniModelName | string | No | 'gpt-4o-mini' | Valid model name | GPT-4.1-Mini model identifier |
| gpt41MiniModelVersion | string | No | '2024-07-18' | Valid version | GPT-4.1-Mini version |
| gpt41MiniCapacityTPM | integer | No | 100 | 1-1000 | GPT-4.1-Mini TPM capacity |
| gpt4oModelName | string | No | 'gpt-4o' | Valid model name | GPT-4o model identifier |
| gpt4oModelVersion | string | No | '2024-08-06' | Valid version | GPT-4o version |
| gpt4oCapacityTPM | integer | No | 50 | 1-1000 | GPT-4o TPM capacity |
| fluxModelName | string | No | 'FLUX-1.1-pro' | Valid model name | FLUX model identifier |
| fluxModelVersion | string | No | 'latest' | Valid version | FLUX version |
| fluxCapacityTPM | integer | No | 10 | 1-1000 | FLUX TPM capacity |
| deepseekModelName | string | No | 'DeepSeek-V3.1' | Valid model name | DeepSeek model identifier |
| deepseekModelVersion | string | No | 'latest' | Valid version | DeepSeek version |
| deepseekCapacityTPM | integer | No | 50 | 1-1000 | DeepSeek TPM capacity |

**Total Parameters**: 19

**Validation Rules**:
- Total TPM across all models: 260
- All names globally/subscription unique
- Location must support all 5 models

---

### 6. Deployment Outputs

**Type**: Deployment result (exported configuration)

**Purpose**: Connection details for client application configuration.

**Properties**:

| Output | Type | Description | Format |
|--------|------|-------------|--------|
| hubResourceId | string | Hub ARM resource ID | /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.MachineLearningServices/workspaces/{hub} |
| projectResourceId | string | Project ARM resource ID | /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.MachineLearningServices/workspaces/{project} |
| aiServicesEndpoint | string | AI Services inference endpoint | https://{name}.{region}.inference.ml.azure.com/ |
| aiServicesKey | string | Workspace-level access key | Sensitive, retrieved via listKeys() |
| gpt41Deployment | object | GPT-4.1 deployment details | { name, model, version, capacity } |
| gpt41MiniDeployment | object | GPT-4.1-Mini deployment details | { name, model, version, capacity } |
| gpt4oDeployment | object | GPT-4o deployment details | { name, model, version, capacity } |
| fluxDeployment | object | FLUX deployment details | { name, model, version, capacity } |
| deepseekDeployment | object | DeepSeek deployment details | { name, model, version, capacity } |

**.env.azure-openai Mapping**:
```bash
AZURE_OPENAI_ENDPOINT=${aiServicesEndpoint}
AZURE_OPENAI_KEY=${aiServicesKey}
AZURE_OPENAI_DEPLOYMENT_GPT41=${gpt41Deployment.name}
AZURE_OPENAI_DEPLOYMENT_GPT41_MINI=${gpt41MiniDeployment.name}
AZURE_OPENAI_DEPLOYMENT_GPT4O=${gpt4oDeployment.name}
AZURE_OPENAI_DEPLOYMENT_FLUX=${fluxDeployment.name}
AZURE_OPENAI_DEPLOYMENT_DEEPSEEK=${deepseekDeployment.name}
```

**Validation Rules**:
- All fields must be present
- Endpoint must be valid URL
- Key must be non-empty
- All deployment objects complete

---

## State Transitions

### Deployment Lifecycle

```
[Parameters Validated] → [Hub Created] → [Project Created] → [AI Services Created] → [Deployments Created] → [Outputs Generated] → [Validated]
         ↓                     ↓                ↓                    ↓                       ↓                       ↓
    [Failed]            [Failed]         [Failed]            [Failed]               [Failed]              [Validated] → [Client Updated]
```

### Resource States

| State | Description | Next States | Rollback |
|-------|-------------|-------------|----------|
| Not Exists | No resources deployed | Creating | N/A |
| Creating | Deployment in progress | Created, Failed | Delete in-progress resources |
| Created | Resources exist | Validated, Deleted | Delete all resources |
| Validated | Health checks pass | In Use | Delete all resources |
| In Use | Client applications connected | Validated, Deleted | Requires client update |
| Deleted | Resources removed | Not Exists | Restore from soft delete (48h) |

---

## Validation Rules Summary

### Cross-Entity Constraints

1. **Location Consistency**: Hub, Project, and AI Services must share same location
2. **Total TPM Quota**: Sum of all deployment capacities = 260 TPM
3. **Name Uniqueness**:
   - Hub name: Globally unique
   - AI Services name: Globally unique
   - Project name: Unique within subscription
   - Deployment names: Unique within AI Services account
4. **Model Availability**: All 5 models must be available in target region
5. **Reference Integrity**: Project.hubResourceId must reference existing Hub

### Bicep Validation

```bicep
// Cross-entity validation example
assert totalCapacity = (gpt41CapacityTPM + gpt41MiniCapacityTPM + gpt4oCapacityTPM + fluxCapacityTPM + deepseekCapacityTPM) == 260

// Location consistency
assert project.location == hub.location
assert aiServices.location == hub.location
```

---

## Schema Version

**Version**: 1.0.0
**Date**: 2025-10-19
**Status**: Complete

---

**Next**: Contract definitions (input-schema.json, output-schema.json)
