# Data Model: Azure Infrastructure as Code

**Feature**: 002-azure-infrastructure-as
**Date**: 2025-10-08
**Constitution**: v1.0.0

## Overview

This document defines the infrastructure entities, their properties, relationships, and validation rules for the Azure Infrastructure as Code implementation.

## Entity Definitions

### 1. Infrastructure Environment

Represents a deployment target with environment-specific configurations.

**Properties**:
- `name` (string, required): Environment identifier
  - Allowed values: `dev`, `staging`, `prod`
  - Validation: Must match regex `^(dev|staging|prod)$`
- `location` (string, required): Azure region for all resources
  - Example: `eastus`, `westus2`, `centralus`
  - Validation: Must be valid Azure region name
- `resourceGroupName` (string, required): Azure resource group name
  - Format: `rg-{projectName}-{environment}`
  - Validation: Max 90 characters, alphanumeric and hyphens only

**Relationships**:
- Contains: 1..* Azure resources (OpenAI, App Service, Static Web App, Application Insights, VNet)

**State Transitions**:
- `not-deployed` → `deploying` → `deployed`
- `deployed` → `updating` → `deployed`
- `deployed` → `failed` (on deployment error)

**Validation Rules**:
- Environment name must be unique within project
- All resources must be in same region (single-region requirement)

### 2. Azure OpenAI Service Instance

Represents the managed OpenAI service with model deployments.

**Properties**:
- `name` (string, required): OpenAI service name
  - Format: `oai-{projectName}-{environment}`
  - Validation: 2-64 characters, lowercase alphanumeric and hyphens
- `sku` (string, required): Pricing tier
  - Default: `S0` (Standard)
  - Validation: Must be valid OpenAI SKU
- `modelDeployments` (array, required): List of model deployments
  - Required models: `gpt-4o`, `gpt-35-turbo`, `dall-e-3`
  - Each deployment includes:
    - `name` (string): Model name
    - `model` (string): Model identifier (e.g., `gpt-4o`, `gpt-35-turbo`)
    - `version` (string): Model version
    - `capacity` (integer): TPM (tokens per minute) capacity
- `publicNetworkAccess` (string, required): `Enabled`
- `networkAcls` (object, optional): Network access control rules
  - `defaultAction` (string): `Allow` or `Deny`
  - `ipRules` (array): Optional IP allowlist

**Relationships**:
- Belongs to: Infrastructure Environment
- Accessed by: App Service (via Managed Identity over public endpoint)

**Validation Rules**:
- Must have exactly 3 model deployments (GPT-4o, GPT-3.5-turbo, DALL-E 3)
- Total capacity across all models must not exceed subscription quota
- Public network access enabled (hybrid networking approach)

### 3. App Service Instance

Represents the backend API hosting environment.

**Properties**:
- `name` (string, required): App Service name
  - Format: `app-{projectName}-{environment}`
  - Validation: 2-60 characters, alphanumeric and hyphens
- `sku` (object, required): Pricing tier (same across all environments)
  - `name` (string): SKU identifier (e.g., `B1`, `P1V2`)
  - `tier` (string): Tier name (e.g., `Basic`, `Premium`)
  - Default: `B1` (Basic)
- `managedIdentityEnabled` (boolean, required): Must be `true`
- `managedIdentityType` (string, required): `SystemAssigned`
- `vnetIntegrationEnabled` (boolean, required): Must be `true`
- `httpsOnly` (boolean, required): Must be `true`
- `minTlsVersion` (string, required): `1.2`

**Relationships**:
- Belongs to: Infrastructure Environment
- Authenticates to: Azure OpenAI Service (via Managed Identity)
- Connected to: Virtual Network (via VNet Integration)
- Monitored by: Application Insights

**Validation Rules**:
- Managed identity must be enabled (system-assigned)
- VNet integration must be configured with valid subnet
- HTTPS-only access enforced
- Minimum TLS version 1.2

### 4. Static Web App Instance

Represents the frontend hosting environment.

**Properties**:
- `name` (string, required): Static Web App name
  - Format: `swa-{projectName}-{environment}`
  - Validation: 2-60 characters, alphanumeric and hyphens
- `sku` (string, required): Pricing tier
  - Default: `Standard`
  - Validation: Must be `Free` or `Standard`
- `repositoryUrl` (string, optional): Git repository URL for CI/CD
- `branch` (string, optional): Git branch name
- `buildProperties` (object, optional): Build configuration
  - `appLocation` (string): Frontend app directory
  - `apiLocation` (string): API directory (if using managed functions)
  - `outputLocation` (string): Build output directory

**Relationships**:
- Belongs to: Infrastructure Environment
- Calls: App Service (backend API)
- Monitored by: Application Insights

**Validation Rules**:
- Must be publicly accessible (required for user access)
- Backend API calls must go through private App Service (via VNet)

### 5. Application Insights Instance

Represents the observability platform.

**Properties**:
- `name` (string, required): Application Insights name
  - Format: `appi-{projectName}-{environment}`
  - Validation: 1-255 characters, alphanumeric, hyphens, periods
- `applicationType` (string, required): `web`
- `retentionInDays` (integer, required): Log retention period
  - Default: `90`
  - Allowed values: 30, 60, 90, 120, 180, 270, 365, 550, 730
- `workspaceResourceId` (string, required): Log Analytics workspace ID

**Relationships**:
- Belongs to: Infrastructure Environment
- Monitors: App Service, Static Web App, Azure OpenAI Service
- Receives: Diagnostic logs and metrics from all resources

**Validation Rules**:
- Must be workspace-based (Log Analytics integration)
- Retention period must be valid Azure value
- Must collect logs from all compute resources

### 6. Virtual Network

Represents the network boundary for App Service VNet integration.

**Properties**:
- `name` (string, required): Virtual Network name
  - Format: `vnet-{projectName}-{environment}`
  - Validation: 2-64 characters, alphanumeric, hyphens, underscores, periods
- `addressPrefix` (string, required): VNet address space
  - Default: `10.0.0.0/16`
  - Validation: Must be valid CIDR notation
- `subnets` (array, required): List of subnets
  - `appServiceSubnet`: For App Service VNet integration (outbound traffic)
    - Address prefix: `10.0.1.0/24`
    - Delegation: `Microsoft.Web/serverFarms`

**Relationships**:
- Belongs to: Infrastructure Environment
- Contains: App Service VNet Integration subnet
- Used by: App Service (for outbound traffic control)

**Validation Rules**:
- Must have App Service integration subnet
- App Service subnet must have delegation to `Microsoft.Web/serverFarms`
- Address space must be valid CIDR notation

### 7. Managed Identity

Represents the Azure AD identity for authentication.

**Properties**:
- `principalId` (string, read-only): Object ID of managed identity
- `tenantId` (string, read-only): Azure AD tenant ID
- `type` (string, required): `SystemAssigned`

**Relationships**:
- Assigned to: App Service
- Has permissions on: Azure OpenAI Service (via Role Assignment)

**Validation Rules**:
- Must be system-assigned type
- Must have role assignment to OpenAI service

### 8. Role Assignment

Represents the authorization mapping for managed identity.

**Properties**:
- `roleDefinitionId` (string, required): Azure role definition ID
  - Value: `5e0bd9bd-7b93-4f28-af87-19fc36ad61bd` (Cognitive Services OpenAI User)
- `principalId` (string, required): Managed identity principal ID
- `principalType` (string, required): `ServicePrincipal`
- `scope` (string, required): Azure OpenAI Service resource ID

**Relationships**:
- Links: Managed Identity → Azure OpenAI Service
- Scoped to: Specific OpenAI resource (not subscription or resource group)

**Validation Rules**:
- Role must be "Cognitive Services OpenAI User" (least privilege)
- Scope must be resource-level (specific OpenAI instance)
- Principal type must be ServicePrincipal

### 9. Resource Tags

Represents metadata applied to all resources.

**Properties**:
- `Environment` (string, required): Environment name
  - Values: `dev`, `staging`, `prod`
- `Project` (string, required): Project name
  - Value: `az-llm`

**Relationships**:
- Applied to: All Azure resources

**Validation Rules**:
- Environment tag must match environment name
- Project tag must be consistent across all resources
- No additional tags required (minimal strategy)

### 10. Deployment Configuration

Represents the parameter values for resource provisioning.

**Properties**:
- `environment` (string, required): Target environment
- `location` (string, required): Azure region
- `projectName` (string, required): Project identifier
- `appServiceSku` (object, required): App Service SKU configuration
- `openAiModels` (array, required): Model deployment configurations
- `tags` (object, required): Resource tags

**Relationships**:
- Inputs to: Bicep template deployment
- Produces: Infrastructure Environment

**Validation Rules**:
- Must validate against Bicep parameter schema
- All required parameters must be provided
- Parameter values must meet resource-specific validation rules

## Entity Relationship Diagram

```
Infrastructure Environment (1)
  ├── Virtual Network (1)
  │   └── App Service Subnet (1)
  │       └── VNet Integration ← App Service (1)
  ├── Azure OpenAI Service (1) [Public with Managed Identity Auth]
  │   ├── GPT-4o Deployment (1)
  │   ├── GPT-3.5-turbo Deployment (1)
  │   └── DALL-E 3 Deployment (1)
  ├── App Service (1) [Public with VNet Integration]
  │   ├── Managed Identity (1)
  │   │   └── Role Assignment → Azure OpenAI (1)
  │   └── VNet Integration → App Service Subnet (1)
  ├── Static Web App (1) [Public]
  │   └── Calls → App Service API (public HTTPS)
  └── Application Insights (1)
      ├── Monitors App Service (1)
      ├── Monitors Static Web App (1)
      └── Receives Diagnostics from all resources (*)

Communication Flow:
Browser → Static Web App (public) → App Service (public HTTPS) → OpenAI (managed identity)
```

## Validation Summary

| Entity | Key Validations |
|--------|----------------|
| Infrastructure Environment | Unique name, valid Azure region |
| Azure OpenAI Service | 3 model deployments, public access enabled |
| App Service | Managed identity enabled, VNet integration configured |
| Static Web App | Public access (required), calls public App Service API |
| Application Insights | Workspace-based, valid retention period |
| Virtual Network | App Service subnet with proper delegation |
| Managed Identity | System-assigned type |
| Role Assignment | Least privilege role, resource-scoped |
| Resource Tags | Environment and Project tags present |
| Deployment Configuration | Schema compliance, all required params |

## Constitutional Alignment

- **Simplicity-First**: Minimal entity complexity, built-in Azure features
- **Azure-Native Integration**: All entities use Azure-managed services
- **Clear Contracts**: Explicit validation rules and relationships
- **Observability**: Application Insights integration for all resources
