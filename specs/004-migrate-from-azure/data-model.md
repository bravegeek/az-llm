# Data Model: Azure AI Foundry Hub-less Deployment

**Feature**: 004-migrate-from-azure
**Date**: 2025-10-20
**Version**: 2.0.0 (Updated for hub-less architecture)

## Entity Relationship Diagram

```
┌─────────────────────────────────┐
│   AI Foundry AIServices         │
│  (CognitiveServices Account)    │
│                                 │
│ - name: string                  │
│ - kind: 'AIServices'            │
│ - location: string              │
│ - sku: { name: 'S0' }           │
│ - customSubDomainName: string   │
│ - allowProjectManagement: true  │
└────────┬──────────────┬─────────┘
         │ 1            │ 1
         │ contains     │ hosts
         │ 1            │ 3
┌────────▼─────────┐    │
│   Project        │    │
│  (Child)         │    │
│                  │    │
│ - name: string   │    │
│ - displayName    │    │
└──────────────────┘    │
                        │
         ┌──────────────┴──────────────┬─────────────────┐
         │                             │                 │
┌────────▼─────────┐    ┌──────────────▼────┐   ┌───────▼──────────┐
│ Model Deployment │    │ Model Deployment  │   │ Model Deployment │
│   (gpt-4)        │    │   (gpt-4o-mini)   │   │   (gpt-4o)       │
│                  │    │                   │   │                  │
│ - name: string   │    │ - name: string    │   │ - name: string   │
│ - capacity: 50   │    │ - capacity: 100   │   │ - capacity: 50   │
│ - version        │    │ - version         │   │ - version        │
└──────────────────┘    └───────────────────┘   └──────────────────┘

Manual Deployments (Portal):
┌──────────────────────────────────────┐
│ Serverless Model: FLUX-1.1-pro       │
│ - Pay-per-token (no TPM)             │
│ - Deployed via AI Foundry portal     │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│ Serverless Model: DeepSeek-V3.1      │
│ - Pay-per-token (no TPM)             │
│ - Deployed via AI Foundry portal     │
└──────────────────────────────────────┘
```

## Entities

### 1. AI Foundry AIServices Account
**Resource Type**: `Microsoft.CognitiveServices/accounts@2025-06-01`

**Properties**:
| Property | Type | Required | Validation | Description |
|----------|------|----------|------------|-------------|
| name | string | Yes | 2-64 chars, alphanumeric/hyphens | Globally unique account name |
| kind | string | Yes | Must be 'AIServices' | Specifies AI Foundry account type |
| location | string | Yes | Valid Azure region | Deployment region |
| sku.name | string | Yes | 'S0' (Standard) | Service tier |
| identity.type | string | Yes | 'SystemAssigned' | Managed identity type |
| customSubDomainName | string | Yes | Globally unique | Subdomain for endpoints |
| allowProjectManagement | boolean | Yes | Must be true | Enables hub-less projects |
| publicNetworkAccess | string | No | 'Enabled' or 'Disabled' | Network access control |
| disableLocalAuth | boolean | No | true/false | Disable key-based auth |

**Computed Properties**:
- `id`: Resource ID (output only)
- `properties.endpoint`: HTTPS endpoint URL
- `identity.principalId`: Managed identity ID

**Relationships**:
- **Contains**: 1 Project (1:1)
- **Hosts**: 3 Model Deployments (1:3)

**Validation Rules**:
- Name must be globally unique across Azure
- customSubDomainName must be globally unique
- Location must support AI Foundry (validate via CLI)
- allowProjectManagement must be true for hub-less projects

**Example**:
```json
{
  "name": "ai-foundry-xyz123",
  "kind": "AIServices",
  "location": "eastus2",
  "sku": { "name": "S0" },
  "identity": { "type": "SystemAssigned" },
  "properties": {
    "customSubDomainName": "ai-xyz123",
    "allowProjectManagement": true,
    "publicNetworkAccess": "Enabled",
    "disableLocalAuth": false
  }
}
```

---

### 2. AI Foundry Project
**Resource Type**: `Microsoft.CognitiveServices/accounts/projects@2025-06-01`

**Properties**:
| Property | Type | Required | Validation | Description |
|----------|------|----------|------------|-------------|
| name | string | Yes | 3-24 chars, alphanumeric/hyphens | Project name (unique within account) |
| location | string | Yes | Must match parent location | Deployment region |
| displayName | string | No | 1-100 chars | Friendly display name |
| description | string | No | Max 500 chars | Project description |

**Computed Properties**:
- `id`: Project resource ID
- `properties.projectId`: Unique project identifier

**Relationships**:
- **Parent**: AI Foundry AIServices Account (1:1)
- **Logical Container**: For model deployments (models deploy to parent account, not project)

**Validation Rules**:
- Name unique within parent account
- Location must match parent AIServices account location
- Cannot be created without parent account

**Example**:
```json
{
  "name": "foundry-project",
  "location": "eastus2",
  "properties": {
    "displayName": "AI Foundry Project",
    "description": "Hub-less project for 5 model deployments"
  }
}
```

---

### 3. Model Deployment (Standard - 3 instances)
**Resource Type**: `Microsoft.CognitiveServices/accounts/deployments@2025-06-01`

**Properties**:
| Property | Type | Required | Validation | Description |
|----------|------|----------|------------|-------------|
| name | string | Yes | Alphanumeric/hyphens | Deployment name |
| sku.name | string | Yes | 'Standard' or 'DataZoneStandard' | Deployment SKU |
| sku.capacity | integer | Yes | 1-1000 (thousands of TPM) | TPM allocation |
| model.format | string | Yes | 'OpenAI' | Model format |
| model.name | string | Yes | Valid model name | Model identifier |
| model.version | string | Yes | Valid version string | Model version |
| versionUpgradeOption | string | No | See options below | Version upgrade policy |
| raiPolicyName | string | No | 'Microsoft.Default' | Content safety policy |

**Version Upgrade Options**:
- `OnceCurrentVersionExpired`: Auto-upgrade when current version deprecated
- `OnceNewDefaultVersionAvailable`: Auto-upgrade to latest
- `NoAutoUpgrade`: Manual version management

**Computed Properties**:
- `id`: Deployment resource ID
- `properties.provisioningState`: Deployment status
- `properties.raiPolicyName`: Applied RAI policy

**Relationships**:
- **Parent**: AI Foundry AIServices Account (3:1)
- **Logical Association**: Project (deployments appear in project context)

**Model-Specific Configuration**:

#### gpt-4 (gpt-4.1)
```json
{
  "name": "gpt-4-deployment",
  "sku": { "name": "Standard", "capacity": 50 },
  "properties": {
    "model": {
      "format": "OpenAI",
      "name": "gpt-4",
      "version": "1106-preview"
    },
    "versionUpgradeOption": "OnceCurrentVersionExpired",
    "raiPolicyName": "Microsoft.Default"
  }
}
```
**TPM**: 50K

#### gpt-4o-mini (gpt-4.1-mini)
```json
{
  "name": "gpt-4o-mini-deployment",
  "sku": { "name": "DataZoneStandard", "capacity": 100 },
  "properties": {
    "model": {
      "format": "OpenAI",
      "name": "gpt-4o-mini",
      "version": "2025-04-14"
    },
    "versionUpgradeOption": "OnceCurrentVersionExpired",
    "raiPolicyName": "Microsoft.Default"
  }
}
```
**TPM**: 100K

#### gpt-4o
```json
{
  "name": "gpt-4o-deployment",
  "sku": { "name": "Standard", "capacity": 50 },
  "properties": {
    "model": {
      "format": "OpenAI",
      "name": "gpt-4o",
      "version": "2024-08-06"
    },
    "versionUpgradeOption": "OnceCurrentVersionExpired",
    "raiPolicyName": "Microsoft.Default"
  }
}
```
**TPM**: 50K

**Total TPM (Bicep-deployed models)**: 200K

**Validation Rules**:
- Model must be available in target region
- TPM capacity must be within quota limits
- Version must be valid for model
- Sum of all capacities <= available quota

---

### 4. Serverless Model Deployments (Manual - 2 instances)

#### FLUX-1.1-pro
**Deployment Method**: Azure AI Foundry Portal (Model Catalog)
**Pricing**: Pay-per-token (no TPM allocation)
**TPM**: N/A (serverless)
**Documentation Required**:
1. Navigate to AI Foundry portal: https://ai.azure.com
2. Select project
3. Go to Model Catalog
4. Search "FLUX-1.1-pro"
5. Click "Deploy" → Serverless API
6. Note endpoint URL and key

#### DeepSeek-V3.1
**Deployment Method**: Azure AI Foundry Portal (Model Catalog)
**Pricing**: Pay-per-token (no TPM allocation)
**TPM**: N/A (serverless)
**Documentation Required**:
1. Navigate to AI Foundry portal: https://ai.azure.com
2. Select project
3. Go to Model Catalog
4. Search "DeepSeek-V3.1"
5. Click "Deploy" → Serverless API
6. Note endpoint URL and key

**Note**: Serverless models cannot be deployed via Bicep. Manual deployment preserves <300 line Bicep constraint.

---

### 5. Deployment Parameters (Input)
**File**: `infra/main.parameters.json`

**Schema**:
```json
{
  "location": "eastus2",
  "aiServicesName": "ai-foundry-unique",
  "customSubDomain": "ai-unique",
  "projectName": "foundry-project",
  "gpt4DeploymentName": "gpt-4-deployment",
  "gpt4Capacity": 50,
  "gpt4Version": "1106-preview",
  "gpt4oMiniDeploymentName": "gpt-4o-mini-deployment",
  "gpt4oMiniCapacity": 100,
  "gpt4oMiniVersion": "2025-04-14",
  "gpt4oDeploymentName": "gpt-4o-deployment",
  "gpt4oCapacity": 50,
  "gpt4oVersion": "2024-08-06"
}
```

**Total Parameters**: 13 (down from 17 due to serverless models)

**Validation**: JSON Schema in `contracts/input-schema.json`

---

### 6. Deployment Outputs
**File**: Generated via `scripts/outputs.sh` → `.env.azure-foundry`

**Schema**:
```bash
AI_SERVICES_ID="<resource-id>"
AI_SERVICES_ENDPOINT="https://<subdomain>.cognitiveservices.azure.com/"
PROJECT_ID="<project-resource-id>"

# Standard models (Bicep-deployed)
GPT4_ENDPOINT="https://<subdomain>.openai.azure.com/"
GPT4_DEPLOYMENT_NAME="gpt-4-deployment"
GPT4_MODEL="gpt-4"
GPT4_VERSION="1106-preview"

GPT4O_MINI_ENDPOINT="https://<subdomain>.openai.azure.com/"
GPT4O_MINI_DEPLOYMENT_NAME="gpt-4o-mini-deployment"
GPT4O_MINI_MODEL="gpt-4o-mini"
GPT4O_MINI_VERSION="2025-04-14"

GPT4O_ENDPOINT="https://<subdomain>.openai.azure.com/"
GPT4O_DEPLOYMENT_NAME="gpt-4o-deployment"
GPT4O_MODEL="gpt-4o"
GPT4O_VERSION="2024-08-06"

# Serverless models (Manual - placeholder)
FLUX_ENDPOINT="<manual-deployment>"
FLUX_KEY="<manual-deployment>"
DEEPSEEK_ENDPOINT="<manual-deployment>"
DEEPSEEK_KEY="<manual-deployment>"
```

**Validation**: JSON Schema in `contracts/output-schema.json`

---

## State Transitions

### AIServices Account
```
[Not Exists] --create--> [Creating] --provision--> [Succeeded]
[Succeeded] --update--> [Updating] --apply--> [Succeeded]
[Succeeded] --delete--> [Deleting] --remove--> [Deleted]
```

### Project
```
[Not Exists] --create--> [Creating] --provision--> [Succeeded]
(Requires parent AIServices in Succeeded state)
```

### Model Deployment
```
[Not Exists] --create--> [Creating] --provision--> [Succeeded]
[Succeeded] --scale--> [Updating] --apply--> [Succeeded]
(Requires parent AIServices in Succeeded state)
```

## Constraints & Dependencies

### Creation Order (Bicep dependency chain)
1. AI Foundry AIServices Account
2. Project (depends on AIServices)
3. Model Deployments (depends on AIServices, parallel creation possible)

### Deletion Order (Reverse)
1. Model Deployments
2. Project
3. AI Foundry AIServices Account

### Validation Sequence
1. Resource group is empty
2. Region supports all 3 models
3. Quota available for 200K TPM
4. Unique names available (AIServices name, subdomain)
5. Bicep deployment
6. Manual serverless deployment (FLUX, DeepSeek)

---

## Compliance Matrix

| Constitutional Principle | Data Model Compliance |
|-------------------------|----------------------|
| **Simplicity-First** | ✅ Hub-less (3 resources vs 4), serverless models manual |
| **Test-First Development** | ✅ Contract schemas define tests before implementation |
| **Azure-Native Integration** | ✅ All Cognitive Services native resources |
| **Clear Contracts** | ✅ JSON Schema validation for inputs/outputs |
| **Observability** | ✅ Deployment states tracked, outputs structured |

---

**Version History**:
- v1.0.0 (2025-10-19): Initial hub-based design
- v2.0.0 (2025-10-20): Updated to hub-less architecture, 3+2 model approach
