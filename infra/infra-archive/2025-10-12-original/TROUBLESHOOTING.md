# Infrastructure Troubleshooting Guide

This guide covers common issues encountered during Azure infrastructure deployment and their solutions.

## Table of Contents

- [Prerequisites Issues](#prerequisites-issues)
- [Authentication and Permissions](#authentication-and-permissions)
- [Deployment Failures](#deployment-failures)
- [Resource-Specific Issues](#resource-specific-issues)
- [Network Configuration](#network-configuration)
- [Security and RBAC](#security-and-rbac)
- [Monitoring and Diagnostics](#monitoring-and-diagnostics)

---

## Prerequisites Issues

### Azure CLI Not Found

**Error**:
```
./infra/scripts/check-prerequisites.sh: line 33: az: command not found
```

**Solution**:
1. Install Azure CLI:
   ```bash
   # Ubuntu/Debian
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

   # macOS
   brew install azure-cli

   # Windows
   # Download from https://aka.ms/installazurecliwindows
   ```
2. Verify installation:
   ```bash
   az version
   ```

### Azure CLI Version Too Old

**Error**:
```
Azure CLI version 2.45.0 is less than required 2.50.0
```

**Solution**:
```bash
# Update Azure CLI
az upgrade

# Verify version
az version
```

### Bicep CLI Not Found

**Error**:
```
Bicep CLI is not installed
```

**Solution**:
```bash
# Install Bicep
az bicep install

# Upgrade to latest version
az bicep upgrade

# Verify version
az bicep version
```

---

## Authentication and Permissions

### Not Logged In

**Error**:
```
Please run 'az login' to setup account.
```

**Solution**:
```bash
# Interactive login
az login

# Login with service principal
az login --service-principal \
  --username <app-id> \
  --password <password-or-cert> \
  --tenant <tenant-id>

# Verify authentication
az account show
```

### Wrong Subscription

**Error**:
Resources deploying to unexpected subscription.

**Solution**:
```bash
# List all subscriptions
az account list --output table

# Set default subscription
az account set --subscription <subscription-id>

# Verify
az account show --query name
```

### Insufficient Permissions

**Error**:
```
AuthorizationFailed: The client does not have authorization to perform action
```

**Solution**:
1. Check required roles:
   - **Contributor** on subscription/resource group
   - **User Access Administrator** (for RBAC role assignments)

2. Request access from subscription owner:
   ```bash
   az role assignment create \
     --assignee <your-email> \
     --role Contributor \
     --scope /subscriptions/<subscription-id>
   ```

3. Verify permissions:
   ```bash
   az role assignment list --assignee <your-email> --output table
   ```

---

## Deployment Failures

### Resource Provider Not Registered

**Error**:
```
The subscription is not registered to use namespace 'Microsoft.CognitiveServices'
```

**Solution**:
```bash
# Register required providers
az provider register --namespace Microsoft.CognitiveServices
az provider register --namespace Microsoft.Web
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.OperationalInsights

# Check registration status
az provider show --namespace Microsoft.CognitiveServices \
  --query registrationState
```

> **Note**: Registration can take 5-10 minutes.

### Quota Exceeded

**Error**:
```
Operation could not be completed as it results in exceeding approved quota
```

**Solution**:
1. Check current quota usage:
   ```bash
   az vm list-usage --location eastus --output table
   ```

2. Request quota increase:
   - Azure Portal → Subscriptions → Usage + quotas
   - Submit support request for quota increase

3. Alternative: Use different region with available capacity

### Deployment Timeout

**Error**:
Deployment hangs or times out after 30+ minutes.

**Solution**:
1. Check deployment status:
   ```bash
   az deployment group show \
     --resource-group rg-az-llm-dev \
     --name <deployment-name> \
     --query properties.provisioningState
   ```

2. View deployment operations:
   ```bash
   az deployment operation group list \
     --resource-group rg-az-llm-dev \
     --name <deployment-name> \
     --query "[?properties.provisioningState=='Failed']"
   ```

3. Cancel stuck deployment:
   ```bash
   az deployment group cancel \
     --resource-group rg-az-llm-dev \
     --name <deployment-name>
   ```

4. Retry deployment

### Template Validation Errors

**Error**:
```
InvalidTemplate: Deployment template validation failed
```

**Solution**:
1. Run linter:
   ```bash
   ./tests/bicep/linter.test.sh
   ```

2. Check syntax:
   ```bash
   az bicep build --file infra/main.bicep
   ```

3. Common issues:
   - Missing required parameters
   - Invalid parameter values
   - Circular dependencies
   - Resource name conflicts

---

## Resource-Specific Issues

### Azure OpenAI Service

#### Region Availability

**Error**:
```
Resource type 'Microsoft.CognitiveServices/accounts' is not available in location 'westus'
```

**Solution**:
1. Check OpenAI availability:
   - Available regions: East US, West Europe, South Central US, etc.
   - See: https://learn.microsoft.com/azure/ai-services/openai/concepts/models

2. Update parameter file:
   ```bicep
   param location = 'eastus'  // Change to supported region
   ```

#### Model Deployment Failures

**Error**:
```
The specified model 'gpt-4o' version '2024-05-13' is not available
```

**Solution**:
1. Check available models:
   ```bash
   az cognitiveservices account list-models \
     --resource-group rg-az-llm-dev \
     --name oai-az-llm-dev
   ```

2. Update model version in parameter file:
   ```bicep
   {
     name: 'gpt-4o'
     model: 'gpt-4o'
     version: '2024-08-06'  // Updated version
     capacity: 10
   }
   ```

#### Capacity Constraints

**Error**:
```
Requested capacity exceeds available quota
```

**Solution**:
1. Start with lower capacity:
   ```bicep
   capacity: 1  // Reduce from 10 to 1
   ```

2. Request quota increase via Azure Portal

### App Service

#### Name Already Taken

**Error**:
```
The website name 'app-az-llm-backend-dev' is already taken
```

**Solution**:
App Service names must be globally unique. Update parameter:
```bicep
param projectName = 'az-llm-<yourname>'  // Add unique suffix
```

#### VNet Integration Failed

**Error**:
```
VNet integration failed: subnet not properly delegated
```

**Solution**:
1. Verify subnet delegation:
   ```bash
   az network vnet subnet show \
     --resource-group rg-az-llm-dev \
     --vnet-name vnet-az-llm-dev \
     --name snet-appservice-integration \
     --query delegations
   ```

2. Should show `Microsoft.Web/serverFarms`

3. Redeploy VNet module if missing

### Static Web App

#### Build Failed

**Error**:
Static Web App deployment fails during build.

**Solution**:
1. Check Static Web App deployment logs in Azure Portal
2. Verify frontend code exists in repository
3. Update app location in Static Web App configuration
4. For now, Static Web App deploys successfully but requires frontend code

---

## Network Configuration

### Subnet Address Space Exhausted

**Error**:
```
Subnet does not have enough addresses
```

**Solution**:
1. Check current subnet size:
   ```bash
   az network vnet subnet show \
     --resource-group rg-az-llm-dev \
     --vnet-name vnet-az-llm-dev \
     --name snet-appservice-integration \
     --query addressPrefix
   ```

2. Increase subnet size in `infra/modules/vnet.bicep`:
   ```bicep
   addressPrefix: '10.0.1.0/24'  // Change from /26 to /24
   ```

### VNet Peering Issues

**Error**:
VNet peering not working (future use case).

**Solution**:
1. Verify peering status
2. Check route tables
3. Ensure no overlapping address spaces
4. Verify NSG rules allow traffic

---

## Security and RBAC

### Role Assignment Failed

**Error**:
```
Principal does not exist in the directory
```

**Solution**:
1. Verify managed identity is created:
   ```bash
   az webapp identity show \
     --resource-group rg-az-llm-dev \
     --name app-az-llm-backend-dev
   ```

2. Add delay in Bicep (identity propagation):
   ```bicep
   // Role assignment depends on App Service
   dependsOn: [
     appservice
   ]
   ```

3. Retry deployment after 1-2 minutes

### Missing RBAC Permissions

**Error**:
```
App Service cannot access Azure OpenAI
```

**Solution**:
1. Verify role assignment:
   ```bash
   az role assignment list \
     --assignee <app-service-principal-id> \
     --scope <openai-resource-id>
   ```

2. Expected role: `Cognitive Services OpenAI User`

3. Manually assign if missing:
   ```bash
   az role assignment create \
     --assignee <principal-id> \
     --role "Cognitive Services OpenAI User" \
     --scope <openai-resource-id>
   ```

### API Keys in App Settings

**Error**:
Security validation fails: API keys found in app settings.

**Solution**:
1. Remove API key settings:
   ```bash
   az webapp config appsettings delete \
     --resource-group rg-az-llm-dev \
     --name app-az-llm-backend-dev \
     --setting-names OPENAI_API_KEY
   ```

2. Use managed identity instead

---

## Monitoring and Diagnostics

### Application Insights Not Collecting Data

**Error**:
No telemetry data in Application Insights.

**Solution**:
1. Verify connection string:
   ```bash
   az monitor app-insights component show \
     --resource-group rg-az-llm-dev \
     --app appi-az-llm-dev \
     --query connectionString
   ```

2. Configure App Service:
   ```bash
   az webapp config appsettings set \
     --resource-group rg-az-llm-dev \
     --name app-az-llm-backend-dev \
     --settings APPLICATIONINSIGHTS_CONNECTION_STRING="<connection-string>"
   ```

3. Restart App Service

### Log Analytics Query Issues

**Error**:
Queries return no results.

**Solution**:
1. Check data ingestion (5-10 minute delay)
2. Verify retention period:
   ```bash
   az monitor log-analytics workspace show \
     --resource-group rg-az-llm-dev \
     --workspace-name law-az-llm-dev \
     --query retentionInDays
   ```

3. Sample query:
   ```kusto
   AppTraces
   | where TimeGenerated > ago(1h)
   | take 10
   ```

---

## Common Script Errors

### deploy.sh: Permission Denied

**Error**:
```
bash: ./infra/scripts/deploy.sh: Permission denied
```

**Solution**:
```bash
chmod +x infra/scripts/*.sh
```

### What-If Analysis Shows Unexpected Changes

**Error**:
Validation shows resources will be deleted/modified unexpectedly.

**Solution**:
1. Review what-if output carefully
2. Check for parameter changes
3. Use `--confirm-with-what-if` for safety:
   ```bash
   az deployment group create \
     --resource-group rg-az-llm-dev \
     --template-file infra/main.bicep \
     --parameters infra/parameters/dev.bicepparam \
     --confirm-with-what-if
   ```

---

## Getting Help

If issues persist:

1. **Check deployment logs**:
   ```bash
   az deployment group show \
     --resource-group rg-az-llm-dev \
     --name <deployment-name> \
     --query properties.error
   ```

2. **View activity log**:
   ```bash
   az monitor activity-log list \
     --resource-group rg-az-llm-dev \
     --max-events 20
   ```

3. **Enable debug logging**:
   ```bash
   az deployment group create \
     --debug \
     --resource-group rg-az-llm-dev \
     --template-file infra/main.bicep \
     --parameters infra/parameters/dev.bicepparam
   ```

4. **Review Azure documentation**:
   - [Bicep troubleshooting](https://learn.microsoft.com/azure/azure-resource-manager/bicep/troubleshoot)
   - [Common deployment errors](https://learn.microsoft.com/azure/azure-resource-manager/troubleshooting/common-deployment-errors)

5. **Check service health**:
   - Azure Portal → Service Health
   - https://status.azure.com/

---

## Quick Reference Commands

```bash
# Check prerequisites
./infra/scripts/check-prerequisites.sh

# Validate before deployment
./infra/scripts/validate.sh --environment dev

# Deploy infrastructure
./infra/scripts/deploy.sh --environment dev

# Verify deployment
./infra/scripts/verify-deployment.sh --environment dev --resource-group rg-az-llm-dev

# Security validation
./infra/scripts/verify-security.sh --environment dev --resource-group rg-az-llm-dev

# View deployment status
az deployment group list --resource-group rg-az-llm-dev --output table

# Check resource group
az resource list --resource-group rg-az-llm-dev --output table

# Delete all resources
./infra/scripts/cleanup.sh --environment dev
```
