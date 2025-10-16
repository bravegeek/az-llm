# Azure OpenAI Model Availability

## Current Deployment Configuration

The infrastructure has been updated to deploy only models available in **eastus2** region.

### ✅ Available Models (Deployed)

| Model | Version | TPM Capacity | Purpose |
|-------|---------|--------------|---------|
| **gpt-4.1** | 2025-04-14 | 50 | Primary GPT model |
| **gpt-4o-mini** | 2024-07-18 | 100 | Cost-effective GPT |
| **gpt-4o** | 2024-08-06 | 50 | High-performance multimodal |

**Total TPM Capacity**: 200

### ❌ Unavailable Models (Commented Out)

The following models were originally planned but are **not available** in Azure OpenAI Service:

- **FLUX-1.1-pro** - Not in Azure catalog
- **DeepSeek-V3.1** - Not in Azure catalog

These have been commented out in [main.bicep](main.bicep) and can be uncommented if/when they become available.

## Checking Model Availability

To check what models are available in your region:

```bash
# List all GPT models in eastus2
az cognitiveservices model list \
  --location eastus2 \
  --query "[?kind=='OpenAI' && contains(model.name, 'gpt')].{Name:model.name, Version:model.version}" \
  -o table

# List all OpenAI models (not just GPT)
az cognitiveservices model list \
  --location eastus2 \
  --query "[?kind=='OpenAI'].{Name:model.name, Version:model.version}" \
  -o table
```

## Other Available Models in eastus2

As of the last check, these additional models are available:

- **gpt-35-turbo** (various versions)
- **gpt-4** (various versions)
- **gpt-4.1-mini** (2025-04-14)
- **gpt-4.1-nano** (2025-04-14)
- **gpt-5-mini** (2025-08-07)
- **gpt-5-nano** (2025-08-07)
- **gpt-5-chat** (2025-08-07)
- **gpt-audio** (2025-08-28)

## Adding New Models

To add a new model deployment:

1. Check availability in your region first
2. Uncomment the parameter section in [main.bicep](main.bicep)
3. Uncomment the resource deployment
4. Add parameters to [main.parameters.json](main.parameters.json)
5. Update the outputs array
6. Test with `az bicep build --file infra/main.bicep`

## Region Considerations

Different Azure regions have different model availability. To check other regions:

```bash
az account list-locations -o table  # List all regions

az cognitiveservices model list \
  --location <region-name> \
  --query "[?kind=='OpenAI'].{Name:model.name, Version:model.version}" \
  -o table
```

Common regions for Azure OpenAI:
- eastus
- eastus2
- westus
- westeurope
- swedencentral
