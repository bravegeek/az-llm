# Parameter Files Guide

## Overview

This directory uses a layered approach for parameter management:

- **`main.parameters.json`** - Committed to git, contains shared/default values
- **`main.parameters.local.json`** - **Ignored by git**, for local overrides and secrets

## Quick Start

### 1. Create Local Parameters File

```bash
cd infra
cp main.parameters.local.json.template main.parameters.local.json
```

### 2. Edit Local Values

Edit `main.parameters.local.json` with your specific values:
- Account names
- Capacity settings
- Any environment-specific configurations

### 3. Deploy with Local Parameters

```bash
# Use local parameters (ignored by git)
./scripts/deploy.sh --parameters main.parameters.local.json

# Or use shared parameters (committed to git)
./scripts/deploy.sh --parameters main.parameters.json
```

## File Patterns

### Ignored by Git (Safe for Secrets)
- `*.local.json` - Local overrides
- `*.secrets.json` - Explicit secrets files
- `.env*` - Environment variables

### Committed to Git (No Secrets!)
- `main.parameters.json` - Shared defaults
- `*.template` - Templates for local setup
- `*.json` (without .local or .secrets suffix)

## Best Practices

### ✅ DO
- Store secrets in `*.local.json` files
- Use Azure Key Vault references for production
- Keep `main.parameters.json` with safe defaults
- Use Managed Identity when possible (no keys!)

### ❌ DON'T
- Commit API keys or secrets to git
- Store production credentials locally
- Share `*.local.json` files

## Azure-Native Security

According to project constitution (Azure-Native Integration principle):

1. **Development**: Use `*.local.json` files (git-ignored)
2. **Production**: Use Azure Key Vault + Managed Identity
3. **CI/CD**: Use Azure DevOps variable groups or GitHub secrets

## Example: Key Vault Integration

```json
{
  "parameters": {
    "apiKey": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{vault}"
        },
        "secretName": "openai-api-key"
      }
    }
  }
}
```

## Troubleshooting

**Q: My `*.local.json` file is showing in git status**
A: Make sure the filename ends with `.local.json` exactly

**Q: How do I add a new secret parameter?**
A: Add it to `main.parameters.local.json` (not `main.parameters.json`)

**Q: Where should I store connection strings?**
A: Use `.env.local` or `*.secrets.json` files (both git-ignored)
