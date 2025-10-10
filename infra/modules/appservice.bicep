// T015: App Service Module
// Deploys App Service Plan and App Service with managed identity and VNet integration

@description('App Service name')
param appServiceName string

@description('Azure region for deployment')
param location string

@description('App Service SKU configuration')
param sku object

@description('VNet subnet ID for VNet integration')
param vnetSubnetId string

@description('Resource tags')
param tags object

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: '${appServiceName}-plan'
  location: location
  tags: tags
  sku: {
    name: sku.name
    tier: sku.tier
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux plans
  }
}

// App Service with managed identity and VNet integration
resource appService 'Microsoft.Web/sites@2023-01-01' = {
  name: appServiceName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      linuxFxVersion: 'NODE|20-lts' // Default runtime
    }
    virtualNetworkSubnetId: vnetSubnetId
  }
}

@description('App Service name')
output appServiceName string = appService.name

@description('App Service managed identity principal ID')
output appServicePrincipalId string = appService.identity.principalId

@description('App Service resource ID')
output appServiceId string = appService.id
