// T014: Azure OpenAI Service Module
// Deploys OpenAI with 3 model deployments (GPT-4o, GPT-3.5-turbo, DALL-E 3)

@description('Azure OpenAI service name')
param openAiName string

@description('Azure region for deployment')
param location string

@description('Azure OpenAI SKU')
param sku string = 'S0'

@description('Model deployments configuration')
param modelDeployments array

@description('Resource tags')
param tags object

resource openAiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Enabled' // Hybrid networking approach
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

@batchSize(1)
resource deployments 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for model in modelDeployments: {
  parent: openAiAccount
  name: model.name
  sku: {
    name: 'Standard'
    capacity: model.capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: model.model
      version: model.version
    }
  }
}]

@description('Azure OpenAI Service endpoint URL')
output openAiEndpoint string = openAiAccount.properties.endpoint

@description('Azure OpenAI Service resource ID')
output openAiResourceId string = openAiAccount.id

@description('Azure OpenAI Service name')
output openAiName string = openAiAccount.name
