// T016: Static Web App Module
// Deploys Static Web App for frontend hosting (public access)

@description('Static Web App name')
param swaName string

@description('Azure region for deployment')
param location string

@description('Static Web App SKU')
param sku string = 'Standard'

@description('Resource tags')
param tags object

resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: swaName
  location: location
  tags: tags
  sku: {
    name: sku
    tier: sku
  }
  properties: {
    // Build and deployment configuration managed separately
    // Frontend is public by design (no VNet integration)
  }
}

@description('Static Web App default hostname')
output swaUrl string = 'https://${staticWebApp.properties.defaultHostname}'

@description('Static Web App name')
output swaName string = staticWebApp.name
