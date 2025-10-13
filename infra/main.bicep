// Minimal single-file Bicep for Azure OpenAI provisioning
// Feature: 003-create-a-minimal
// Deploys 5 models: gpt-4.1, gpt-4.1-mini, gpt-4o, FLUX-1.1-pro, DeepSeek-V3.1
// Total TPM capacity: 260 (50+100+50+10+50)

// ============================================================================
// PARAMETERS
// ============================================================================

@description('Azure region for deployment')
param location string

@description('Globally unique name for OpenAI account')
@minLength(2)
@maxLength(64)
param openAIAccountName string

@description('Optional AI Foundry project name for organizational tagging')
param aiFoundryProjectName string = ''

// GPT-4.1 (Primary GPT model)
@description('GPT-4.1 model name')
param gpt41ModelName string = 'gpt-4.1'

@description('GPT-4.1 model version')
param gpt41ModelVersion string = '0409'

@description('GPT-4.1 capacity (TPM)')
@minValue(1)
@maxValue(1000)
param gpt41CapacityTPM int = 50

// GPT-4.1-Mini (Cost-effective GPT)
@description('GPT-4o-mini model name')
param gpt41MiniModelName string = 'gpt-4o-mini'

@description('GPT-4o-mini model version')
param gpt41MiniModelVersion string = '2024-07-18'

@description('GPT-4o-mini capacity (TPM)')
@minValue(1)
@maxValue(1000)
param gpt41MiniCapacityTPM int = 100

// GPT-4o (High-performance multimodal)
@description('GPT-4o model name')
param gpt4oModelName string = 'gpt-4o'

@description('GPT-4o model version')
param gpt4oModelVersion string = '2024-08-06'

@description('GPT-4o capacity (TPM)')
@minValue(1)
@maxValue(1000)
param gpt4oCapacityTPM int = 50

// FLUX-1.1-pro (Image generation)
@description('FLUX-1.1-pro model name')
param fluxModelName string = 'FLUX-1.1-pro'

@description('FLUX-1.1-pro model version')
param fluxModelVersion string = '2024-11-04'

@description('FLUX-1.1-pro capacity (TPM)')
@minValue(1)
@maxValue(1000)
param fluxCapacityTPM int = 10

// DeepSeek-V3.1 (Alternative LLM)
@description('DeepSeek-V3.1 model name')
param deepseekModelName string = 'DeepSeek-V3.1'

@description('DeepSeek-V3.1 model version')
param deepseekModelVersion string = '2024-05-01'

@description('DeepSeek-V3.1 capacity (TPM)')
@minValue(1)
@maxValue(1000)
param deepseekCapacityTPM int = 50

// ============================================================================
// RESOURCES
// ============================================================================

resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIAccountName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: openAIAccountName
    publicNetworkAccess: 'Enabled'
  }
  tags: {
    aiFoundryProject: aiFoundryProjectName
    deployedBy: 'bicep-minimal'
    feature: '003-create-a-minimal'
  }
}

// Model Deployment 1: GPT-4.1 (Primary)
resource gpt41Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAIAccount
  name: 'gpt-4.1'
  sku: {
    name: 'Standard'
    capacity: gpt41CapacityTPM
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt41ModelName
      version: gpt41ModelVersion
    }
  }
}

// Model Deployment 2: GPT-4.1-Mini (Cost-effective)
resource gpt41MiniDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAIAccount
  name: 'gpt-4.1-mini'
  sku: {
    name: 'Standard'
    capacity: gpt41MiniCapacityTPM
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt41MiniModelName
      version: gpt41MiniModelVersion
    }
  }
}

// Model Deployment 3: GPT-4o (High-performance)
resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAIAccount
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: gpt4oCapacityTPM
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt4oModelName
      version: gpt4oModelVersion
    }
  }
}

// Model Deployment 4: FLUX-1.1-pro (Image generation)
resource fluxDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAIAccount
  name: 'FLUX-1.1-pro'
  sku: {
    name: 'Standard'
    capacity: fluxCapacityTPM
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: fluxModelName
      version: fluxModelVersion
    }
  }
}

// Model Deployment 5: DeepSeek-V3.1 (Alternative LLM)
resource deepseekDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  parent: openAIAccount
  name: 'DeepSeek-V3.1'
  sku: {
    name: 'Standard'
    capacity: deepseekCapacityTPM
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: deepseekModelName
      version: deepseekModelVersion
    }
  }
}

// ============================================================================
// OUTPUTS
// ============================================================================

@description('Azure OpenAI API endpoint URL')
output endpoint string = openAIAccount.properties.endpoint

@description('Primary access key for API authentication')
output apiKey string = openAIAccount.listKeys().key1

@description('Full Azure resource ID')
output resourceId string = openAIAccount.id

@description('Array of 5 model deployment names')
output deploymentNames array = [
  gpt41Deployment.name
  gpt41MiniDeployment.name
  gpt4oDeployment.name
  fluxDeployment.name
  deepseekDeployment.name
]

@description('Deployed Azure region')
output location string = location

@description('OpenAI account name')
output accountName string = openAIAccount.name
