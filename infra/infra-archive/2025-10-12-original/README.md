# Azure Infrastructure as Code

This directory contains the Bicep Infrastructure as Code (IaC) for the az-llm project, providing a complete Azure deployment for a private AI chatbot and image generator.

## Architecture Overview

The infrastructure implements a **hybrid networking** approach:

- **Azure OpenAI Service**: Public endpoint with managed identity authentication (no private endpoint)
- **App Service**: VNet integration for outbound traffic control, system-assigned managed identity
- **Static Web App**: Public frontend for user access
- **Monitoring**: Workspace-based Application Insights with Log Analytics

### Resources Deployed

| Resource | Purpose | Naming Convention |
|----------|---------|-------------------|
| Virtual Network | App Service integration | `vnet-az-llm-{env}` |
| Azure OpenAI Service | GPT-4o, GPT-3.5 Turbo, DALL-E 3 | `oai-az-llm-{env}` |
| App Service Plan | Backend API hosting | `asp-az-llm-{env}` |
| App Service | Backend API | `app-az-llm-backend-{env}` |
| Static Web App | Frontend UI | `swa-az-llm-frontend-{env}` |
| Log Analytics Workspace | Centralized logging | `law-az-llm-{env}` |
| Application Insights | Observability | `appi-az-llm-{env}` |

## Prerequisites

Before deploying, ensure you have:

1. **Azure CLI** >= 2.50.0
2. **Bicep CLI** >= 0.20.0
3. **Azure Subscription** with appropriate permissions
4. **Resource Providers** registered:
   - `Microsoft.CognitiveServices`
   - `Microsoft.Web`
   - `Microsoft.Network`
   - `Microsoft.Insights`
   - `Microsoft.OperationalInsights`

### Check Prerequisites

```bash
./infra/scripts/check-prerequisites.sh
```

## Project Structure

```
infra/
├── main.bicep                  # Main orchestrator
├── modules/                    # Bicep modules
│   ├── vnet.bicep             # Virtual Network
│   ├── openai.bicep           # Azure OpenAI Service
│   ├── appservice.bicep       # App Service + Plan
│   ├── staticwebapp.bicep     # Static Web App
│   └── monitoring.bicep       # Log Analytics + App Insights
├── parameters/                 # Environment-specific parameters
│   ├── dev.bicepparam         # Development
│   ├── staging.bicepparam     # Staging
│   └── prod.bicepparam        # Production
├── scripts/                    # Deployment and validation scripts
│   ├── check-prerequisites.sh # Validates Azure CLI and Bicep versions
│   ├── deploy.sh              # Deploys infrastructure
│   ├── validate.sh            # Pre-deployment validation
│   ├── verify-deployment.sh   # Post-deployment verification
│   ├── verify-security.sh     # Security compliance checks
│   └── cleanup.sh             # Resource cleanup
└── README.md                   # This file
```

## Quick Start

### 1. Validate Infrastructure

Before deploying, validate your Bicep templates and parameters:

```bash
./infra/scripts/validate.sh --environment dev
```

This performs:
- Bicep linting
- Template compilation
- Parameter validation
- What-if analysis (shows planned changes)

### 2. Deploy Infrastructure

Deploy to your chosen environment:

```bash
# Development
./infra/scripts/deploy.sh --environment dev

# Staging
./infra/scripts/deploy.sh --environment staging

# Production
./infra/scripts/deploy.sh --environment prod
```

The script will:
1. Run pre-flight checks
2. Create resource group if needed
3. Deploy all resources
4. Display deployment outputs

Expected deployment time: **5-10 minutes**

### 3. Verify Deployment

After deployment completes, verify all resources:

```bash
./infra/scripts/verify-deployment.sh --environment dev --resource-group rg-az-llm-dev
```

This checks:
- Resource existence
- VNet integration
- Managed identity configuration
- RBAC role assignments
- Service configurations

### 4. Validate Security

Run security compliance checks:

```bash
./infra/scripts/verify-security.sh --environment dev --resource-group rg-az-llm-dev
```

This validates:
- HTTPS enforcement
- TLS 1.2+ requirement
- Managed identity usage
- No API keys in app settings
- Network security configuration

## Deployment Outputs

After successful deployment, the following outputs are available:

| Output | Description | Usage |
|--------|-------------|-------|
| `openAiEndpoint` | Azure OpenAI endpoint URL | Configure backend API |
| `openAiResourceId` | OpenAI resource ID | RBAC assignments |
| `appServiceName` | Backend App Service name | Deployment targets |
| `appServicePrincipalId` | Managed identity principal ID | RBAC verification |
| `staticWebAppUrl` | Frontend URL | User access |
| `applicationInsightsConnectionString` | App Insights connection | Telemetry configuration |
| `applicationInsightsInstrumentationKey` | Instrumentation key | Legacy telemetry |

Retrieve outputs:

```bash
az deployment group show \
  --resource-group rg-az-llm-dev \
  --name <deployment-name> \
  --query properties.outputs
```

## Environment Configuration

### Development (dev)

- **SKU**: Basic B1 (App Service)
- **Models**: GPT-4o, GPT-3.5 Turbo, DALL-E 3
- **Capacity**: 10 TPM per model (1 TPM for DALL-E 3)
- **Use case**: Testing, experimentation

### Staging (staging)

- **SKU**: Basic B1 (App Service)
- **Models**: Same as development
- **Capacity**: Same as development
- **Use case**: Pre-production validation

### Production (prod)

- **SKU**: Basic B1 (App Service)
- **Models**: Same as development
- **Capacity**: Same as development
- **Use case**: Live user traffic

> **Note**: Update SKUs and capacity in `parameters/*.bicepparam` for production workloads.

## Security Best Practices

This infrastructure implements:

1. **Managed Identity**: App Service uses system-assigned identity (no secrets)
2. **RBAC**: "Cognitive Services OpenAI User" role for App Service → OpenAI
3. **HTTPS Only**: Enforced on App Service
4. **TLS 1.2+**: Minimum TLS version required
5. **FTP Disabled**: App Service FTP access disabled
6. **VNet Integration**: App Service integrated with VNet
7. **Workspace-based Monitoring**: Application Insights linked to Log Analytics

### No Private Endpoints

This implementation uses **public endpoints with managed identity** instead of private endpoints because:
- Simplicity-first approach (constitutional principle)
- Managed identity provides strong authentication
- Azure OpenAI's public endpoint supports managed identity
- Private endpoints add complexity without significant security benefit for this use case

## Cost Estimation

Estimated monthly costs (East US region):

| Resource | SKU | Estimated Cost |
|----------|-----|----------------|
| Azure OpenAI | GPT-4o, GPT-3.5, DALL-E 3 | Pay-per-use (varies) |
| App Service | Basic B1 | ~$13/month |
| Static Web App | Standard | Free tier available |
| Log Analytics | Pay-as-you-go | ~$2/GB ingested |
| Application Insights | Workspace-based | Included in Log Analytics |
| Virtual Network | Standard | Free |

> **Note**: OpenAI costs depend on usage. Monitor with Azure Cost Management.

## Updating Infrastructure

To update existing infrastructure:

1. Modify Bicep templates or parameters
2. Validate changes:
   ```bash
   ./infra/scripts/validate.sh --environment dev
   ```
3. Review what-if output
4. Deploy updates:
   ```bash
   ./infra/scripts/deploy.sh --environment dev
   ```

Bicep deployments are **idempotent** - only changes are applied.

## Cleanup

To delete all resources in an environment:

```bash
# With confirmation prompts
./infra/scripts/cleanup.sh --environment dev

# Force delete (no prompts - DANGEROUS)
./infra/scripts/cleanup.sh --environment dev --force
```

> **WARNING**: This permanently deletes all resources. Production environments require typing "DELETE PRODUCTION".

## Testing

Run all infrastructure tests:

```bash
./tests/run-all-tests.sh
```

Test categories:
- **Bicep Tests**: Linting, build, parameter validation, policy compliance
- **Integration Tests**: Fresh deployment, updates, multi-environment, security

## Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues and solutions.

Quick diagnostics:

```bash
# Check Azure CLI authentication
az account show

# Check resource provider registration
az provider show --namespace Microsoft.CognitiveServices --query registrationState

# View deployment logs
az deployment group show --resource-group rg-az-llm-dev --name <deployment-name>
```

## References

- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-services/openai/)
- [App Service VNet Integration](https://learn.microsoft.com/azure/app-service/overview-vnet-integration)
- [Managed Identity Best Practices](https://learn.microsoft.com/azure/active-directory/managed-identities-azure-resources/overview)

## Support

For issues or questions:
1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Review [project specification](../specs/002-azure-infrastructure-as/spec.md)
3. Check Azure deployment logs
4. Review resource-specific documentation

## License

This infrastructure code follows the same license as the az-llm project.
