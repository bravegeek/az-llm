# Research: Azure Infrastructure as Code

**Feature**: 002-azure-infrastructure-as
**Date**: 2025-10-08
**Constitution**: v1.0.0

## Research Summary

This document captures technical research and decisions for implementing Azure infrastructure using Bicep, addressing the deferred questions from the specification and planning phases.

## 1. Bicep Modular Infrastructure Best Practices

### Decision
Use modular Bicep templates with a main orchestrator and separate modules for each resource type (VNet, OpenAI, App Service, Static Web App, Application Insights).

### Rationale
- **Reusability**: Individual modules can be tested and deployed independently
- **Maintainability**: Changes to one resource type don't affect others
- **Testing**: Each module can have isolated validation tests
- **Constitutional alignment**: Follows Simplicity-First principle (built-in Bicep features, no custom abstractions)

### Alternatives Considered
- **Single monolithic template**: Rejected due to poor maintainability and testing challenges
- **Terraform**: Rejected in favor of Azure-native Bicep (constitutional requirement)
- **ARM JSON templates**: Rejected in favor of more readable Bicep syntax

### Implementation Pattern
```bicep
// main.bicep orchestrates all modules
module vnet 'modules/vnet.bicep' = { ... }
module openai 'modules/openai.bicep' = { ... }
module appservice 'modules/appservice.bicep' = { ... }
```

## 2. Hybrid Networking Configuration

### Decision
Use hybrid networking approach: public Azure OpenAI Service with managed identity authentication, App Service with VNet integration for outbound traffic control, and public Static Web App.

### Rationale
- **Simplicity**: No private endpoint complexity (DNS zones, private link management)
- **Security**: Managed identity provides strong authentication without network isolation
- **Cost-effective**: Avoids private endpoint hourly charges (~$7-10/month per endpoint)
- **Constitutional alignment**: Follows Simplicity-First principle (avoiding unnecessary complexity)
- **Flexibility**: Public OpenAI endpoint accessible from multiple clients with proper auth
- **Development-friendly**: No VPN/bastion required for local development

### Alternatives Considered
- **Full private endpoints**: Rejected due to added complexity (DNS management, private link setup, private DNS zones)
- **Fully public with API keys**: Rejected due to secret management overhead (violates FR-008)
- **Service endpoints**: Rejected as they're deprecated in favor of private endpoints

### Implementation Pattern
```bicep
// Azure OpenAI: Public endpoint with managed identity auth
resource openAiService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiName
  properties: {
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'  // Or 'Deny' with IP allowlist for added security
    }
  }
}

// App Service: VNet integration for outbound traffic
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  properties: {
    virtualNetworkSubnetId: vnetIntegrationSubnetId
  }
}

// Static Web App: Public (required for user access)
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: swaName
  sku: { name: 'Standard', tier: 'Standard' }
  // No VNet integration (public by design)
}
```

### Required Configuration
- VNet with subnet for App Service VNet integration (delegation to Microsoft.Web/serverFarms)
- Managed identity on App Service for OpenAI authentication
- Optional: Network ACLs on OpenAI for IP-based restrictions (if needed)

## 3. Managed Identity Role Assignments

### Decision
Use system-assigned managed identity for App Service with "Cognitive Services OpenAI User" role assignment scoped to the OpenAI resource.

### Rationale
- **Security**: No secrets or connection strings in configuration (FR-008)
- **Least privilege**: Uses minimum required permission for OpenAI access (FR-007)
- **Constitutional alignment**: Follows Azure-Native Integration principle (managed identity pattern)

### Alternatives Considered
- **User-assigned managed identity**: Rejected for simplicity (system-assigned is simpler for single app scenario)
- **Service principal with client secret**: Rejected due to secret management overhead and constitutional violation
- **Broader role assignment**: Rejected to maintain least privilege

### Implementation Pattern
```bicep
resource appServiceManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'app-identity'
  location: location
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: openAiService
  name: guid(appService.id, openAiService.id, 'Cognitive Services OpenAI User')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
    principalId: appServiceManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
```

### Role Details
- **Role**: Cognitive Services OpenAI User (5e0bd9bd-7b93-4f28-af87-19fc36ad61bd)
- **Permissions**: Can create completions, embeddings, images; cannot manage deployments
- **Scope**: Resource-level (specific OpenAI instance only)

## 4. Static Web App Integration with Public Backends

### Decision
Deploy Static Web App as fully public frontend that calls public App Service backend API (authenticated via managed identity from App Service to OpenAI).

### Rationale
- **Simplicity**: Direct communication without complex networking
- **Architecture**: Public Static Web App → Public App Service → Public OpenAI (managed identity auth)
- **Security**: Backend protected by managed identity (no API keys), frontend is inherently public
- **Constitutional alignment**: Hybrid approach balances usability with security

### Alternatives Considered
- **Static Web App with private backend**: Rejected as Static Web App doesn't support private endpoint access to backends
- **Static Web App with Azure Functions**: Considered but rejected to avoid additional compute layer
- **Application Gateway + backend**: Rejected for added complexity (constitutional violation)

### Implementation Pattern
```bicep
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: swaName
  location: location
  sku: { name: 'Standard', tier: 'Standard' }
  properties: {
    // Public frontend
    // No VNet integration needed
  }
}
```

### Configuration Notes
- Static Web App: Public frontend (required for user access)
- App Service: Public endpoint with optional firewall rules, VNet integration for outbound
- Communication flow: Browser → Static Web App → App Service (HTTPS) → OpenAI (managed identity)

## 5. Environment Parameter Management

### Decision
Use Bicep parameter files (`.bicepparam`) for each environment with centralized validation schema.

### Rationale
- **Type safety**: Bicep parameter files provide compile-time validation
- **Environment isolation**: Separate files prevent cross-environment configuration errors
- **Version control**: Parameter files tracked in git for audit trail (FR-016)
- **Constitutional alignment**: Clear Contracts principle (versioned parameter schemas)

### Alternatives Considered
- **Azure DevOps variable groups**: Rejected to keep infrastructure-as-code complete
- **Key Vault parameter references**: Rejected as we have no secrets (managed identity only)
- **Single parameter file with conditionals**: Rejected for complexity and error-proneness

### Implementation Pattern
```bicep
// dev.bicepparam
using './main.bicep'

param environment = 'dev'
param location = 'eastus'
param projectName = 'az-llm'
param appServiceSku = 'B1'
param openAiModels = [
  { name: 'gpt-4o', capacity: 10 }
  { name: 'gpt-35-turbo', capacity: 10 }
  { name: 'dall-e-3', capacity: 1 }
]
```

### Parameter Structure
- **Common parameters**: `environment`, `location`, `projectName`
- **Resource parameters**: SKUs, capacities, model deployments
- **Tags**: Minimal set (Environment, Project) per clarification

## 6. Deployment Validation and Testing

### Decision
Implement three-tier testing strategy: linting, policy validation, and deployment validation.

### Rationale
- **Constitutional compliance**: Supports Test-First Development principle
- **Quality assurance**: Catches errors before Azure deployment
- **Fast feedback**: Local validation before cloud deployment

### Testing Layers

#### Layer 1: Bicep Linting
```bash
# linter.test.sh
az bicep build --file infra/main.bicep
az bicep lint --file infra/main.bicep
```
- Validates Bicep syntax and best practices
- Runs locally before deployment
- Fast feedback (seconds)

#### Layer 2: Azure Policy Validation
```bash
# policy.test.sh
az policy state list --resource-group $RG --query "[?complianceState=='NonCompliant']"
```
- Validates compliance with Azure policies
- Checks security and governance requirements
- Runs as pre-deployment gate

#### Layer 3: Deployment Validation
```bash
# deployment.test.sh
az deployment group validate \
  --resource-group $RG \
  --template-file infra/main.bicep \
  --parameters @infra/parameters/dev.bicepparam
```
- Validates template can deploy successfully
- Checks dependencies and configurations
- Runs before actual deployment (what-if mode)

### Alternatives Considered
- **Unit tests for Bicep**: No standard framework available
- **Manual validation**: Rejected for lack of repeatability
- **Only deployment validation**: Rejected for slow feedback loop

## 7. Compliance and Security Defaults

### Decision
Use Azure default encryption, audit logging, and security settings; enable diagnostic settings to Application Insights.

### Rationale
- **Encryption**: Azure resources have encryption-at-rest enabled by default
- **Audit logging**: Azure Activity Log captures all ARM operations automatically
- **Network security**: Private endpoints provide network isolation (FR-011)
- **Observability**: Application Insights centralized logging (constitutional requirement)

### Default Settings Applied
- **Encryption at rest**: Enabled by default on all Azure services
- **TLS in transit**: Enforced (minimum TLS 1.2)
- **Audit logs**: Azure Activity Log (90-day retention)
- **Diagnostic settings**: All resources → Application Insights
- **Network isolation**: Private endpoints (no public access)

### Compliance Status (FR-014)
- ✅ Encryption at rest: Azure default (managed keys)
- ✅ Network isolation: Private endpoints
- ✅ Audit logging: Activity Log + Application Insights
- ✅ No secrets in code: Managed identity only

### Implementation Pattern
```bicep
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'to-app-insights'
  scope: targetResource
  properties: {
    workspaceId: appInsights.id
    logs: [
      { category: 'allLogs', enabled: true }
    ]
    metrics: [
      { category: 'AllMetrics', enabled: true }
    ]
  }
}
```

## 8. Backup and Disaster Recovery

### Decision
Leverage Azure's built-in geo-redundancy and configuration backup; no additional DR infrastructure required for MVP.

### Rationale
- **Stateless infrastructure**: Bicep templates are the source of truth (re-deployable)
- **Azure OpenAI**: Managed service with Microsoft-managed backups
- **App Service**: Stateless (no persistent data)
- **Static Web App**: Git repository is backup
- **Simplicity**: Follows constitutional Simplicity-First principle

### Backup Strategy
1. **Infrastructure code**: Git repository (version controlled)
2. **Configuration**: Parameter files in git
3. **Azure resources**: Re-create from Bicep templates
4. **Application Insights data**: 90-day default retention

### Disaster Recovery (FR-017)
- **RPO**: Minutes (redeploy from git)
- **RTO**: 10 minutes (deployment time)
- **Scope**: Single region (per clarification)
- **Process**: Redeploy infrastructure to new region if needed

### Deferred Enhancements
- Multi-region deployment (future feature)
- Automated failover (future feature)
- Extended log retention (configure if needed)

## 9. Template Orchestration Approach

### Decision
Use single main orchestrator (`main.bicep`) that calls modular templates with dependency management.

### Rationale
- **Simplicity**: One deployment command per environment
- **Dependencies**: Bicep handles resource dependencies automatically
- **Testability**: Modules can be tested independently
- **Constitutional alignment**: Simplicity-First principle

### Orchestration Pattern
```bicep
// main.bicep
module vnet 'modules/vnet.bicep' = { ... }

module openai 'modules/openai.bicep' = {
  dependsOn: [vnet]  // Explicit dependency
  params: {
    subnetId: vnet.outputs.privateEndpointSubnetId
  }
}

module appservice 'modules/appservice.bicep' = {
  dependsOn: [openai, vnet]
  params: {
    openAiEndpoint: openai.outputs.endpoint
    subnetId: vnet.outputs.appServiceSubnetId
  }
}
```

### Deployment Command
```bash
az deployment group create \
  --resource-group rg-az-llm-dev \
  --template-file infra/main.bicep \
  --parameters @infra/parameters/dev.bicepparam
```

### Alternatives Considered (FR-015)
- **Separate resource deployments**: Rejected due to manual dependency management
- **Nested templates**: Rejected for added complexity
- **Helm/Terraform**: Rejected for non-Azure-native tooling

## Summary of Decisions

| Question | Decision | Constitutional Alignment |
|----------|----------|-------------------------|
| Template structure | Modular Bicep with main orchestrator | Simplicity-First (built-in features) |
| Private endpoints | Dedicated subnet with DNS integration | Azure-Native Integration |
| Managed identity | System-assigned with scoped role | Azure-Native Integration, Clear Contracts |
| Static Web App | Public frontend, private backend via VNet | Simplicity-First (hybrid approach) |
| Parameters | Bicep parameter files per environment | Clear Contracts (versioned) |
| Testing | 3-tier: lint, policy, deployment | Test-First Development |
| Compliance | Azure defaults + diagnostic settings | Observability |
| Backup/DR | Git + re-deployable templates | Simplicity-First |
| Orchestration | Single main template | Simplicity-First |

## Next Phase

All NEEDS CLARIFICATION items resolved. Ready for Phase 1: Design & Contracts.
