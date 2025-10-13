// T013: Virtual Network Module
// Deploys VNet with App Service integration subnet

@description('Virtual Network name')
param vnetName string

@description('Azure region for deployment')
param location string

@description('VNet address space (CIDR notation)')
param addressPrefix string = '10.0.0.0/16'

@description('Resource tags')
param tags object

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'appServiceSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

@description('Virtual Network resource ID')
output vnetId string = vnet.id

@description('App Service integration subnet ID')
output appServiceSubnetId string = vnet.properties.subnets[0].id
