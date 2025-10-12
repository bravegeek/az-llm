# Quickstart: Azure Infrastructure Deployment

**Feature**: 002-azure-infrastructure-as
**Date**: 2025-10-08
**Constitution**: v1.0.0

## Overview

This quickstart guide provides step-by-step instructions for deploying Azure infrastructure for the az-llm project. It covers the primary user scenarios defined in the feature specification.

## Prerequisites

- Azure CLI installed and configured (`az --version`)
- Bicep CLI installed (`az bicep version`)
- Azure subscription with required permissions
- Git repository cloned locally

## Scenario 1: Fresh Deployment (No Existing Resources)

**User Story**: As a DevOps engineer, I need to deploy infrastructure to a new environment from scratch.

### Steps

1. **Authenticate to Azure**
   ```bash
   az login
   az account set --subscription "<subscription-id>"
   ```

2. **Create Resource Group**
   ```bash
   ENVIRONMENT="dev"  # or staging, prod
   LOCATION="eastus"
   PROJECT="az-llm"

   az group create \
     --name "rg-${PROJECT}-${ENVIRONMENT}" \
     --location "${LOCATION}" \
     --tags Environment="${ENVIRONMENT}" Project="${PROJECT}"
   ```

3. **Validate Bicep Templates (Pre-deployment)**
   ```bash
   # Lint Bicep files
   az bicep build --file infra/main.bicep
   az bicep lint --file infra/main.bicep

   # Validate deployment (what-if mode)
   az deployment group validate \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --template-file infra/main.bicep \
     --parameters @infra/parameters/${ENVIRONMENT}.bicepparam
   ```

4. **Deploy Infrastructure**
   ```bash
   az deployment group create \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --template-file infra/main.bicep \
     --parameters @infra/parameters/${ENVIRONMENT}.bicepparam \
     --name "${PROJECT}-infra-$(date +%Y%m%d-%H%M%S)"
   ```

5. **Verify Deployment**
   ```bash
   # Check deployment status
   az deployment group show \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "${PROJECT}-infra-<timestamp>" \
     --query "properties.provisioningState"

   # List deployed resources
   az resource list \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --output table
   ```

6. **Retrieve Deployment Outputs**
   ```bash
   # Get all outputs
   az deployment group show \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "${PROJECT}-infra-<timestamp>" \
     --query "properties.outputs" \
     --output json

   # Get specific values for app configuration
   OPENAI_ENDPOINT=$(az deployment group show \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "${PROJECT}-infra-<timestamp>" \
     --query "properties.outputs.openAiEndpoint.value" \
     --output tsv)

   APP_INSIGHTS_CONN=$(az deployment group show \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "${PROJECT}-infra-<timestamp>" \
     --query "properties.outputs.applicationInsightsConnectionString.value" \
     --output tsv)
   ```

### Expected Outputs

- ✅ Resource group created with correct tags
- ✅ Virtual network with App Service integration subnet deployed
- ✅ Azure OpenAI Service with 3 model deployments (public with managed identity auth)
- ✅ App Service with managed identity and VNet integration
- ✅ Static Web App provisioned (public)
- ✅ Application Insights configured
- ✅ OpenAI Service deployed with public access (managed identity auth)
- ✅ Role assignment: App Service → OpenAI (Cognitive Services OpenAI User)
- ✅ Deployment outputs contain connection information

### Success Criteria

1. **All resources deployed**: `az resource list` shows 8+ resources
2. **No secrets in configuration**: Parameter files contain no keys or passwords
3. **Managed identity configured**: App Service has system-assigned identity
4. **Hybrid networking**: OpenAI service public with managed identity, App Service with VNet integration
5. **Observability enabled**: All resources send diagnostics to Application Insights

---

## Scenario 2: Update Deployment (Infrastructure Changes)

**User Story**: As a DevOps engineer, I need to update existing infrastructure without data loss.

### Steps

1. **Make Configuration Changes**
   ```bash
   # Example: Update OpenAI model capacity in parameter file
   code infra/parameters/${ENVIRONMENT}.bicepparam
   # Change: capacity from 10 to 20 for gpt-4o
   ```

2. **Preview Changes (What-If)**
   ```bash
   az deployment group what-if \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --template-file infra/main.bicep \
     --parameters @infra/parameters/${ENVIRONMENT}.bicepparam
   ```

3. **Review What-If Output**
   - ✅ Green (Create): New resources to be added
   - ✅ Blue (Modify): Existing resources to be updated
   - ⚠️ Orange (Delete): Resources to be removed (verify intentional)
   - ❌ Red (Replace): Resources to be deleted and recreated (check data impact)

4. **Apply Updates**
   ```bash
   az deployment group create \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --template-file infra/main.bicep \
     --parameters @infra/parameters/${ENVIRONMENT}.bicepparam \
     --name "${PROJECT}-infra-update-$(date +%Y%m%d-%H%M%S)" \
     --mode Incremental
   ```

5. **Verify Update Success**
   ```bash
   # Check updated resource properties
   az cognitiveservices account deployment show \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "oai-${PROJECT}-${ENVIRONMENT}" \
     --deployment-name "gpt-4o" \
     --query "properties.sku.capacity"
   ```

### Expected Outcomes

- ✅ Only modified resources are updated (incremental mode)
- ✅ No resource recreation unless explicitly required
- ✅ Deployment completes without errors
- ✅ Application remains available during update

### Failure Scenarios

**If deployment fails**:
```bash
# Check deployment errors
az deployment group show \
  --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
  --name "${PROJECT}-infra-update-<timestamp>" \
  --query "properties.error"

# Rollback approach (if needed)
# 1. Revert parameter file changes in git
# 2. Re-deploy with previous parameters
git checkout HEAD~1 -- infra/parameters/${ENVIRONMENT}.bicepparam
az deployment group create \
  --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
  --template-file infra/main.bicep \
  --parameters @infra/parameters/${ENVIRONMENT}.bicepparam
```

---

## Scenario 3: Multi-Environment Deployment

**User Story**: As a DevOps engineer, I need to deploy the same infrastructure to dev, staging, and prod with environment-specific configurations.

### Steps

1. **Deploy Development Environment**
   ```bash
   az deployment group create \
     --resource-group "rg-az-llm-dev" \
     --template-file infra/main.bicep \
     --parameters @infra/parameters/dev.bicepparam
   ```

2. **Deploy Staging Environment**
   ```bash
   az deployment group create \
     --resource-group "rg-az-llm-staging" \
     --template-file infra/main.bicep \
     --parameters @infra/parameters/staging.bicepparam
   ```

3. **Deploy Production Environment**
   ```bash
   az deployment group create \
     --resource-group "rg-az-llm-prod" \
     --template-file infra/main.bicep \
     --parameters @infra/parameters/prod.bicepparam
   ```

4. **Verify Environment Isolation**
   ```bash
   # List all environments
   for ENV in dev staging prod; do
     echo "=== $ENV Environment ==="
     az resource list \
       --resource-group "rg-az-llm-${ENV}" \
       --output table
     echo ""
   done
   ```

5. **Verify Consistent Configuration**
   ```bash
   # All environments should use same SKU (per clarification)
   for ENV in dev staging prod; do
     SKU=$(az appservice plan list \
       --resource-group "rg-az-llm-${ENV}" \
       --query "[0].sku.name" \
       --output tsv)
     echo "${ENV}: ${SKU}"
   done
   # Expected: dev: B1, staging: B1, prod: B1
   ```

### Expected Outcomes

- ✅ 3 independent resource groups (dev, staging, prod)
- ✅ Same resource types in each environment
- ✅ Same SKUs across all environments (per clarification)
- ✅ Environment-specific tags applied correctly
- ✅ No resource naming conflicts
- ✅ Isolated virtual networks per environment

---

## Scenario 4: Security Validation

**User Story**: As a DevOps engineer, I need to verify that managed identities are configured and no secrets are exposed.

### Steps

1. **Verify Managed Identity Configuration**
   ```bash
   # Check App Service has system-assigned identity
   az webapp identity show \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "app-${PROJECT}-${ENVIRONMENT}" \
     --query "principalId"
   ```

2. **Verify Role Assignment**
   ```bash
   # Get managed identity principal ID
   PRINCIPAL_ID=$(az webapp identity show \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "app-${PROJECT}-${ENVIRONMENT}" \
     --query "principalId" \
     --output tsv)

   # Check role assignment to OpenAI
   az role assignment list \
     --assignee "${PRINCIPAL_ID}" \
     --scope "/subscriptions/<subscription-id>/resourceGroups/rg-${PROJECT}-${ENVIRONMENT}/providers/Microsoft.CognitiveServices/accounts/oai-${PROJECT}-${ENVIRONMENT}" \
     --query "[].{Role:roleDefinitionName, Scope:scope}" \
     --output table

   # Expected: Role = "Cognitive Services OpenAI User"
   ```

3. **Verify Hybrid Networking Configuration**
   ```bash
   # Check OpenAI public network access is enabled (hybrid approach)
   az cognitiveservices account show \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "oai-${PROJECT}-${ENVIRONMENT}" \
     --query "properties.publicNetworkAccess" \
     --output tsv
   # Expected: Enabled

   # Verify network ACLs (optional)
   az cognitiveservices account show \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "oai-${PROJECT}-${ENVIRONMENT}" \
     --query "properties.networkAcls"
   ```

4. **Verify No Secrets in Configuration**
   ```bash
   # Check parameter files for sensitive values
   grep -r "password\|secret\|key\|connectionString" infra/parameters/
   # Expected: No matches (or only parameter names, no actual secrets)

   # Check App Service configuration
   az webapp config appsettings list \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "app-${PROJECT}-${ENVIRONMENT}" \
     --query "[?contains(name, 'KEY') || contains(name, 'SECRET')].{Name:name, Value:value}"
   # Expected: Empty or only references to Key Vault/managed identity
   ```

5. **Verify VNet Integration**
   ```bash
   # Check App Service VNet integration
   az webapp vnet-integration list \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "app-${PROJECT}-${ENVIRONMENT}" \
     --output table
   ```

### Expected Outcomes

- ✅ App Service has system-assigned managed identity
- ✅ Managed identity has "Cognitive Services OpenAI User" role on OpenAI resource
- ✅ OpenAI Service has public network access enabled (hybrid networking)
- ✅ Managed identity authentication configured (no API keys)
- ✅ No secrets, passwords, or keys in parameter files
- ✅ App Service has VNet integration configured
- ✅ All security requirements (FR-007, FR-008, FR-011) satisfied

---

## Scenario 5: Deployment Failure Handling

**User Story**: As a DevOps engineer, I need clear error messages when deployments fail.

### Common Failure Scenarios

#### 1. Subscription Quota Exceeded
```bash
# Error: Quota exceeded for OpenAI TPM
# Solution: Reduce capacity in parameter file or request quota increase
az cognitiveservices usage list \
  --location "${LOCATION}" \
  --query "[?name.value=='OpenAI.Standard.Tokens']"
```

#### 2. Resource Name Conflict
```bash
# Error: Resource name already exists
# Solution: Use unique deployment name or delete existing resource
az resource list \
  --name "oai-${PROJECT}-${ENVIRONMENT}" \
  --output table
```

#### 3. VNet Subnet Conflict
```bash
# Error: Subnet already exists or address space overlaps
# Solution: Verify subnet configuration or use existing subnet
az network vnet subnet list \
  --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
  --vnet-name "vnet-${PROJECT}-${ENVIRONMENT}" \
  --output table
```

#### 4. Insufficient Permissions
```bash
# Error: Authorization failed
# Solution: Verify role assignments
az role assignment list \
  --assignee $(az account show --query "user.name" --output tsv) \
  --scope "/subscriptions/<subscription-id>/resourceGroups/rg-${PROJECT}-${ENVIRONMENT}" \
  --output table
# Required: Contributor or Owner on resource group
```

### Debugging Steps

1. **Get Detailed Error Information**
   ```bash
   az deployment group show \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --name "${PROJECT}-infra-<timestamp>" \
     --query "properties.error" \
     --output json
   ```

2. **Check Activity Log**
   ```bash
   az monitor activity-log list \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --max-events 50 \
     --query "[?level=='Error'].{Time:eventTimestamp, Operation:operationName.localizedValue, Status:status.localizedValue}"
   ```

3. **Validate Template Offline**
   ```bash
   # Dry-run validation
   az deployment group validate \
     --resource-group "rg-${PROJECT}-${ENVIRONMENT}" \
     --template-file infra/main.bicep \
     --parameters @infra/parameters/${ENVIRONMENT}.bicepparam
   ```

---

## Testing Checklist

Use this checklist to validate infrastructure deployment:

### Pre-Deployment
- [ ] Azure CLI authenticated (`az account show`)
- [ ] Bicep templates linted (`az bicep lint`)
- [ ] Parameter files validated against schema
- [ ] Resource group exists with correct tags
- [ ] Sufficient subscription quotas available

### Post-Deployment
- [ ] All resources deployed (8+ resources in `az resource list`)
- [ ] Deployment outputs contain required values
- [ ] Managed identity configured on App Service
- [ ] Role assignment exists: App Service → OpenAI
- [ ] OpenAI Service public access enabled (hybrid networking)
- [ ] Managed identity authentication configured
- [ ] VNet integration configured on App Service
- [ ] Application Insights receiving telemetry
- [ ] Tags applied: Environment, Project
- [ ] No secrets in parameter files or app settings

### Multi-Environment
- [ ] Dev environment deployed successfully
- [ ] Staging environment deployed successfully
- [ ] Prod environment deployed successfully
- [ ] Same SKUs across all environments
- [ ] Environment tags correctly applied
- [ ] Resource names follow naming convention

---

## Cleanup (Optional)

To remove all infrastructure:

```bash
# Delete resource group (WARNING: deletes all resources)
az group delete \
  --name "rg-${PROJECT}-${ENVIRONMENT}" \
  --yes \
  --no-wait

# Verify deletion
az group exists --name "rg-${PROJECT}-${ENVIRONMENT}"
# Expected: false
```

---

## Next Steps

After successful infrastructure deployment:

1. **Configure Application**: Use deployment outputs to configure backend API
2. **Deploy Application Code**: Deploy backend to App Service, frontend to Static Web App
3. **Test End-to-End**: Verify application can access OpenAI via managed identity
4. **Monitor**: Check Application Insights for telemetry and logs

---

## Constitutional Alignment

- ✅ **Simplicity-First**: Single deployment command per environment
- ✅ **Test-First Development**: Validation tests run before deployment
- ✅ **Azure-Native Integration**: Bicep and Azure CLI only
- ✅ **Clear Contracts**: OpenAPI schema defines inputs/outputs
- ✅ **Observability**: Application Insights configured for all resources
