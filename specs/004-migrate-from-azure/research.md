# Research: Azure AI Foundry Migration

**Feature**: 004-migrate-from-azure
**Date**: 2025-10-19
**Status**: Complete

## Research Topics

### 1. Azure AI Foundry Resource Hierarchy

**Decision**: Use Microsoft.MachineLearningServices/workspaces for Hub and Project resources

**Research Findings**:
- **Hub Resource Type**: `Microsoft.MachineLearningServices/workspaces` with `kind: 'Hub'`
- **Project Resource Type**: `Microsoft.MachineLearningServices/workspaces` with `kind: 'Project'`
- **Deployment Resource Type**: Nested under Project workspace

**Required Properties**:
- Hub:
  - `name`: Globally unique, 3-33 characters, alphanumeric and hyphens
  - `location`: Azure region
  - `kind`: 'Hub'
  - `sku`: { name: 'Basic' } (default tier)
  - `identity`: { type: 'SystemAssigned' } for managed identity

- Project:
  - `name`: Unique within subscription, 3-33 characters
  - `location`: Must match Hub location
  - `kind`: 'Project'
  - `hubResourceId`: Reference to parent Hub
  - `properties`: { friendlyName, description }

- Model Deployment:
  - Deployed via Azure OpenAI connection within AI Foundry Project
  - Uses AI Services resource type for model deployments
  - TPM capacity configuration same as standalone OpenAI

**Rationale**: Azure AI Foundry uses Azure Machine Learning Services workspaces as the underlying resource type, with Hub and Project as specialization kinds. This maintains Azure-native integration while providing AI-specific management capabilities.

**Alternatives Considered**:
- Standalone Azure OpenAI (rejected - migration requirement)
- Azure ML Classic (rejected - deprecated)

### 2. Model Availability in AI Foundry

**Decision**: Region-specific validation required; models availability varies by region

**Research Findings**:
- **gpt-4.1**: Available in eastus, eastus2, westus, westus3, northcentralus
- **gpt-4.1-mini** (as gpt-4o-mini): Available in most regions including eastus2
- **gpt-4o**: Available in eastus, eastus2, westus, westus3
- **FLUX-1.1-pro**: Limited availability, check Azure AI Foundry model catalog per region
- **DeepSeek-V3.1**: Availability via Azure AI model catalog, region-specific

**Validation Approach**:
- Use `az ml model list` to query available models in target region
- Implement pre-deployment validation in validate.sh script
- Fail fast with clear error if model unavailable

**Rationale**: Model availability in AI Foundry is region-specific and changes over time. Pre-deployment validation prevents partial deployments and provides clear error messages.

**Alternatives Considered**:
- Assume all models available (rejected - causes deployment failures)
- Deploy only available models (rejected - violates feature requirements)

### 3. AI Foundry vs OpenAI Output Differences

**Decision**: Output structure requires mapping; endpoints and authentication differ

**Research Findings**:
- **Endpoint Format**:
  - OpenAI: `https://{account-name}.openai.azure.com/`
  - AI Foundry: `https://{workspace-name}.{region}.inference.ml.azure.com/`

- **Authentication**:
  - Both support managed identity
  - AI Foundry uses workspace-scoped keys
  - Key retrieval via `az ml workspace show` command

- **Output Structure**:
  - Must include: hubResourceId, projectResourceId, workspaceName
  - Model endpoints: per-deployment inference endpoints
  - Keys: workspace-level keys (not deployment-specific)

**Format Mapping**:
```json
{
  "AZURE_OPENAI_ENDPOINT": "<ai-foundry-workspace-endpoint>",
  "AZURE_OPENAI_KEY": "<workspace-key>",
  "AZURE_OPENAI_DEPLOYMENT_GPT41": "<deployment-name>",
  "AZURE_OPENAI_DEPLOYMENT_GPT41_MINI": "<deployment-name>",
  "AZURE_OPENAI_DEPLOYMENT_GPT4O": "<deployment-name>",
  "AZURE_OPENAI_DEPLOYMENT_FLUX": "<deployment-name>",
  "AZURE_OPENAI_DEPLOYMENT_DEEPSEEK": "<deployment-name>"
}
```

**Rationale**: Maintaining .env.azure-openai compatibility requires mapping AI Foundry workspace endpoints to OpenAI-compatible environment variable names. This minimizes client application changes.

**Alternatives Considered**:
- New output format (rejected - breaks existing integrations)
- Proxy layer (rejected - violates simplicity-first)

### 4. Bicep Resource Type Naming

**Decision**: Use Microsoft.MachineLearningServices/workspaces with API version 2024-04-01 or later

**Research Findings**:
- **API Version**: 2024-04-01 (stable), 2024-07-01-preview (latest features)
- **Resource Types**:
  ```bicep
  // Hub
  resource hub 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
    name: hubName
    location: location
    kind: 'Hub'
    sku: { name: 'Basic' }
    identity: { type: 'SystemAssigned' }
    properties: {
      friendlyName: hubName
      description: 'Azure AI Foundry Hub for LLM deployments'
    }
  }

  // Project
  resource project 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
    name: projectName
    location: location
    kind: 'Project'
    identity: { type: 'SystemAssigned' }
    properties: {
      friendlyName: projectName
      description: 'AI Foundry Project for model deployments'
      hubResourceId: hub.id
    }
  }

  // AI Services connection for model deployments
  resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
    name: aiServicesName
    location: location
    kind: 'AIServices'
    sku: { name: 'S0' }
    properties: {
      customSubDomainName: aiServicesName
    }
  }

  // Model deployments as child resources
  resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
    parent: aiServices
    name: deploymentName
    properties: {
      model: {
        format: 'OpenAI'
        name: modelName
        version: modelVersion
      }
    }
    sku: {
      name: 'Standard'
      capacity: capacityTPM
    }
  }
  ```

**Rationale**: AI Foundry Hub and Project use ML Services workspaces with specific `kind` property. Model deployments use AI Services resource with deployments as child resources, maintaining OpenAI-compatible API surface.

**Alternatives Considered**:
- Use preview API versions (rejected - stability concerns)
- Separate resource types for hub/project (rejected - not Azure architecture)

### 5. Migration Path Validation

**Decision**: Three-phase validation before resource deletion

**Research Findings**:
- **Phase 1: Deployment Validation**
  - Bicep deployment succeeds
  - All resources created (hub, project, 5 deployments)
  - No deployment errors in Azure portal

- **Phase 2: Connectivity Validation**
  - All 5 model endpoints respond to health checks
  - Authentication works with workspace keys
  - TPM capacity matches specifications

- **Phase 3: Integration Validation**
  - Quickstart scenarios pass
  - Test suite passes against new infrastructure
  - Output file format correct

**Rollback Strategy**:
- Keep old OpenAI resources until Phase 3 complete
- Document old resource IDs before deletion
- Azure resource recovery window: 48 hours (soft delete)

**Cut-Over Steps**:
1. Deploy AI Foundry infrastructure (parallel)
2. Run validation phases 1-3
3. Update client applications with new endpoints
4. Verify client connectivity
5. Delete old OpenAI resources
6. Archive old resource documentation

**Rationale**: Three-phase validation ensures infrastructure readiness before committing to migration. Phased approach allows rollback if issues discovered.

**Alternatives Considered**:
- Blue-green deployment (rejected - violates simplicity-first)
- Instant cut-over (rejected - high risk)
- Gradual traffic shift (rejected - requires proxy layer)

## Constitutional Compliance

All research decisions comply with constitutional principles:
- **Simplicity-First**: Single Bicep file, minimal scripts, no new frameworks
- **Test-First**: Validation phases ensure testability
- **Azure-Native**: Using Azure ML Services and AI Services natively
- **Clear Contracts**: JSON Schema for inputs/outputs
- **Observability**: Validation logging, health checks

## Unresolved Questions

None - All NEEDS CLARIFICATION items from spec.md resolved through research.

## References

- Azure AI Foundry Documentation: https://learn.microsoft.com/azure/ai-studio/
- Azure ML Workspace API: https://learn.microsoft.com/azure/templates/microsoft.machinelearningservices/workspaces
- Azure AI Services API: https://learn.microsoft.com/azure/templates/microsoft.cognitiveservices/accounts
- Bicep Documentation: https://learn.microsoft.com/azure/azure-resource-manager/bicep/

---
**Status**: Complete | **Next**: Phase 1 (Design & Contracts)
