// T018: Main Orchestration Template
// Deploys all Azure infrastructure resources with proper dependencies

@description('Target environment (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string

@description('Azure region for all resources')
param location string

@description('Project identifier for resource naming')
@minLength(2)
@maxLength(20)
param projectName string

@description('App Service SKU configuration')
param appServiceSku object

@description('Azure OpenAI model deployments')
@minLength(3)
@maxLength(3)
param openAiModels array

@description('Resource tags')
param tags object

// Resource naming
var vnetName = 'vnet-${projectName}-${environment}'
var openAiName = 'oai-${projectName}-${environment}'
var appServiceName = 'app-${projectName}-${environment}'
var swaName = 'swa-${projectName}-${environment}'
var appInsightsName = 'appi-${projectName}-${environment}'

// 1. Virtual Network (foundation for VNet integration)
module vnet './modules/vnet.bicep' = {
  name: 'vnet-deployment'
  params: {
    vnetName: vnetName
    location: location
    addressPrefix: '10.0.0.0/16'
    tags: tags
  }
}

// 2. Application Insights (observability foundation)
module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  params: {
    appInsightsName: appInsightsName
    location: location
    retentionInDays: 90
    tags: tags
  }
}

// 3. Azure OpenAI Service (deployed in parallel with App Service)
module openai './modules/openai.bicep' = {
  name: 'openai-deployment'
  params: {
    openAiName: openAiName
    location: location
    sku: 'S0'
    modelDeployments: openAiModels
    tags: tags
  }
}

// 4. App Service (depends on VNet for integration)
module appservice './modules/appservice.bicep' = {
  name: 'appservice-deployment'
  params: {
    appServiceName: appServiceName
    location: location
    sku: appServiceSku
    vnetSubnetId: vnet.outputs.appServiceSubnetId
    tags: tags
  }
  dependsOn: [
    vnet
  ]
}

// 5. Static Web App (frontend - no dependencies)
module staticwebapp './modules/staticwebapp.bicep' = {
  name: 'staticwebapp-deployment'
  params: {
    swaName: swaName
    location: location
    sku: 'Standard'
    tags: tags
  }
}

// 6. Role Assignment: App Service → OpenAI (Cognitive Services OpenAI User)
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(appservice.outputs.appServiceId, openai.outputs.openAiResourceId, 'Cognitive Services OpenAI User')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
    principalId: appservice.outputs.appServicePrincipalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    openai
    appservice
  ]
}

// Outputs for application configuration
@description('Azure OpenAI Service endpoint URL')
output openAiEndpoint string = openai.outputs.openAiEndpoint

@description('Azure OpenAI Service resource ID')
output openAiResourceId string = openai.outputs.openAiResourceId

@description('App Service name')
output appServiceName string = appservice.outputs.appServiceName

@description('App Service managed identity principal ID')
output appServicePrincipalId string = appservice.outputs.appServicePrincipalId

@description('Static Web App default hostname')
output staticWebAppUrl string = staticwebapp.outputs.swaUrl

@description('Application Insights connection string')
output applicationInsightsConnectionString string = monitoring.outputs.appInsightsConnectionString

@description('Application Insights instrumentation key (legacy)')
output applicationInsightsInstrumentationKey string = monitoring.outputs.appInsightsInstrumentationKey
