# Quick Start - Azure OpenAI Deployment

## Prerequisites

1. Azure CLI installed and logged in
2. Azure subscription with access to Azure OpenAI Service

## Step-by-Step Deployment

### 1. Login to Azure

```bash
az login
```

### 2. Create Resource Group

```bash
# Choose a unique name for your resource group
RESOURCE_GROUP="rg-llm-prod"
LOCATION="eastus2"

az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 3. (Optional) Create Local Parameters File

If you want to customize parameters:

```bash
cd infra
cp main.parameters.local.json.template main.parameters.local.json

# Edit the file with your values
nano main.parameters.local.json
```

**Required parameters to change:**
- `openAIAccountName` - Must be globally unique (2-64 chars, alphanumeric and hyphens)
- `location` - Azure region (default: eastus2)

### 4. Validate Infrastructure

```bash
./scripts/validate.sh
```

Expected output: `✅ All validation checks passed!`

### 5. Deploy Infrastructure

**Using default parameters:**
```bash
./scripts/deploy.sh $RESOURCE_GROUP infra/main.parameters.json
```

**Using local parameters:**
```bash
./scripts/deploy.sh $RESOURCE_GROUP infra/main.parameters.local.json
```

### 6. Extract Outputs to .env File

```bash
# Get the deployment name from the previous output (format: main-YYYYMMDD-HHMMSS)
DEPLOYMENT_NAME="main-20250115-143022"  # Replace with actual deployment name

./scripts/outputs.sh $RESOURCE_GROUP $DEPLOYMENT_NAME
```

This creates `.env.azure-openai` with your endpoint and API key.

## What Gets Deployed

| Resource | Type | Details |
|----------|------|---------|
| **OpenAI Account** | `Microsoft.CognitiveServices/accounts` | S0 SKU, Public access enabled |
| **gpt-4.1** | Model Deployment | Version: 2025-04-14, Capacity: 50 TPM |
| **gpt-4o-mini** | Model Deployment | Version: 2024-07-18, Capacity: 100 TPM |
| **gpt-4o** | Model Deployment | Version: 2024-08-06, Capacity: 50 TPM |

**Total Capacity**: 200 TPM (Tokens Per Minute)

## Outputs

After deployment, you'll receive:

- `endpoint` - Azure OpenAI API endpoint URL
- `apiKey` - Primary access key (⚠️ keep secret!)
- `resourceId` - Full Azure resource ID
- `deploymentNames` - Array of 3 model deployment names
- `location` - Deployed region
- `accountName` - OpenAI account name

## Configuration Files

| File | Purpose | Git Status |
|------|---------|------------|
| `main.bicep` | Infrastructure definition | ✅ Committed |
| `main.parameters.json` | Shared parameters | ✅ Committed |
| `main.parameters.local.json.template` | Template for local config | ✅ Committed |
| `main.parameters.local.json` | Your local secrets | ❌ **Ignored** |

## Troubleshooting

### Error: "The model ... is not supported"

Check [MODEL_AVAILABILITY.md](MODEL_AVAILABILITY.md) for available models in your region.

```bash
az cognitiveservices model list --location eastus2 \
  --query "[?kind=='OpenAI'].{Name:model.name, Version:model.version}" \
  -o table
```

### Error: "Resource group not found"

Create the resource group first:
```bash
az group create --name <your-rg-name> --location eastus2
```

### Error: "The account name ... is already taken"

Change `openAIAccountName` to a globally unique value in your parameters file.

### Validation Fails

Run individual tests:
```bash
./tests/bicep/linter.test.sh
./tests/bicep/build.test.sh
./tests/bicep/parameter-validation.test.sh
```

## Next Steps

1. **Test the deployment**: Use the API endpoint and key from outputs
2. **Set up monitoring**: Enable Application Insights for observability
3. **Configure access**: Set up managed identity and RBAC
4. **Add more models**: See [MODEL_AVAILABILITY.md](MODEL_AVAILABILITY.md)

## Cleanup

To delete all resources:

```bash
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

⚠️ **Warning**: This permanently deletes all resources in the resource group!

## Additional Resources

- [Azure OpenAI Documentation](https://learn.microsoft.com/azure/cognitive-services/openai/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Model Availability Guide](MODEL_AVAILABILITY.md)
- [Parameter Files Guide](PARAMETERS.md)
