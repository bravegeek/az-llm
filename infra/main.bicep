// Hub-less Azure AI Foundry infrastructure (Feature 004)
// AIServices account (kind: AIServices) + Project + 3 Model Deployments
// Total TPM: 200K (50K gpt-4 + 100K gpt-4o-mini + 50K gpt-4o)
// FLUX-1.1-pro and DeepSeek-V3.1 are serverless (manual deployment via portal)

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Azure region for deployment')
param location string

@description('Globally unique name for AI Foundry AIServices account')
@minLength(2)
@maxLength(64)
param aiServicesName string

@description('Globally unique subdomain for AI Services endpoint')
@minLength(2)
@maxLength(63)
param customSubDomain string

@description('Name for AI Foundry Project (unique within account)')
@minLength(3)
@maxLength(24)
param projectName string

@description('Friendly display name for project')
param projectDisplayName string = 'AI Foundry Project'

// GPT-4 Model Configuration
@description('GPT-4 deployment name')
param gpt4DeploymentName string = 'gpt-4-deployment'

@description('GPT-4 model version')
param gpt4Version string = '1106-preview'

@description('GPT-4 capacity in thousands of TPM')
@minValue(1)
@maxValue(1000)
param gpt4Capacity int = 50

// GPT-4o-mini Model Configuration
@description('GPT-4o-mini deployment name')
param gpt4oMiniDeploymentName string = 'gpt-4o-mini-deployment'

@description('GPT-4o-mini model version')
param gpt4oMiniVersion string = '2025-04-14'

@description('GPT-4o-mini capacity in thousands of TPM')
@minValue(1)
@maxValue(1000)
param gpt4oMiniCapacity int = 100

// GPT-4o Model Configuration
@description('GPT-4o deployment name')
param gpt4oDeploymentName string = 'gpt-4o-deployment'

@description('GPT-4o model version')
param gpt4oVersion string = '2024-08-06'

@description('GPT-4o capacity in thousands of TPM')
@minValue(1)
@maxValue(1000)
param gpt4oCapacity int = 50

// ============================================================================
// RESOURCES
// ============================================================================

// T015: AI Foundry AIServices Account (hub-less)
resource aiServices 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' = {
  name: aiServicesName
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: customSubDomain
    allowProjectManagement: true
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
  }
  tags: {
    feature: '004-migrate-from-azure'
    architecture: 'hub-less'
  }
}

// T016: AI Foundry Project (child of AIServices)
resource project 'Microsoft.CognitiveServices/accounts/projects@2024-06-01-preview' = {
  parent: aiServices
  name: projectName
  location: location
  properties: {
    displayName: projectDisplayName
    description: 'Hub-less AI Foundry project for 3 model deployments'
  }
}

// T017: GPT-4 Deployment
resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = {
  parent: aiServices
  name: gpt4DeploymentName
  sku: {
    name: 'Standard'
    capacity: gpt4Capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: gpt4Version
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
    raiPolicyName: 'Microsoft.Default'
  }
}

// T018: GPT-4o-mini Deployment
resource gpt4oMiniDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = {
  parent: aiServices
  name: gpt4oMiniDeploymentName
  sku: {
    name: 'DataZoneStandard'
    capacity: gpt4oMiniCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o-mini'
      version: gpt4oMiniVersion
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
    raiPolicyName: 'Microsoft.Default'
  }
}

// T019: GPT-4o Deployment
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = {
  parent: aiServices
  name: gpt4oDeploymentName
  sku: {
    name: 'Standard'
    capacity: gpt4oCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: gpt4oVersion
    }
    versionUpgradeOption: 'OnceCurrentVersionExpired'
    raiPolicyName: 'Microsoft.Default'
  }
}

// ============================================================================
// OUTPUTS (T020)
// ============================================================================

@description('AI Services resource ID')
output aiServicesResourceId string = aiServices.id

@description('Project resource ID')
output projectResourceId string = project.id

@description('AI Services endpoint URL')
output aiServicesEndpoint string = 'https://${customSubDomain}.openai.azure.com/'

@description('GPT-4 deployment details')
output gpt4Deployment object = {
  deploymentName: gpt4Deployment.name
  model: 'gpt-4'
  version: gpt4Version
  capacity: gpt4Capacity
  endpoint: 'https://${customSubDomain}.openai.azure.com/'
}

@description('GPT-4o-mini deployment details')
output gpt4oMiniDeployment object = {
  deploymentName: gpt4oMiniDeployment.name
  model: 'gpt-4o-mini'
  version: gpt4oMiniVersion
  capacity: gpt4oMiniCapacity
  endpoint: 'https://${customSubDomain}.openai.azure.com/'
}

@description('GPT-4o deployment details')
output gpt4oDeployment object = {
  deploymentName: gpt4oDeployment.name
  model: 'gpt-4o'
  version: gpt4oVersion
  capacity: gpt4oCapacity
  endpoint: 'https://${customSubDomain}.openai.azure.com/'
}

@description('FLUX-1.1-pro serverless model placeholder')
output fluxDeployment object = {
  deploymentStatus: 'manual-required'
  model: 'FLUX-1.1-pro'
  deploymentInstructions: 'Navigate to https://ai.azure.com, select project, go to Model Catalog, search FLUX-1.1-pro, click Deploy → Serverless API'
}

@description('DeepSeek-V3.1 serverless model placeholder')
output deepseekDeployment object = {
  deploymentStatus: 'manual-required'
  model: 'DeepSeek-V3.1'
  deploymentInstructions: 'Navigate to https://ai.azure.com, select project, go to Model Catalog, search DeepSeek-V3.1, click Deploy → Serverless API'
}
