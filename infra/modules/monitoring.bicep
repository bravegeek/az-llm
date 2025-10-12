// T017: Application Insights Module
// Deploys Log Analytics Workspace and Application Insights for observability

@description('Application Insights name')
param appInsightsName string

@description('Azure region for deployment')
param location string

@description('Log retention period in days')
@allowed([30, 60, 90, 120, 180, 270, 365, 550, 730])
param retentionInDays int = 90

@description('Resource tags')
param tags object

// Log Analytics Workspace (required for workspace-based App Insights)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${appInsightsName}-workspace'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
  }
}

// Application Insights (workspace-based)
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    RetentionInDays: retentionInDays
  }
}

@description('Application Insights connection string')
output appInsightsConnectionString string = appInsights.properties.ConnectionString

@description('Application Insights instrumentation key (legacy)')
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey

@description('Log Analytics Workspace resource ID')
output workspaceId string = logAnalyticsWorkspace.id
