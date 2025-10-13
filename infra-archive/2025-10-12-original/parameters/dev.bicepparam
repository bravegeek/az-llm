// T021: Development Environment Parameters
using '../main.bicep'

param environment = 'dev'
param location = 'eastus'
param projectName = 'az-llm'

param appServiceSku = {
  name: 'B1'
  tier: 'Basic'
}

param openAiModels = [
  {
    name: 'gpt-4o'
    model: 'gpt-4o'
    version: '2024-05-13'
    capacity: 10
  }
  {
    name: 'gpt-35-turbo'
    model: 'gpt-35-turbo'
    version: '0613'
    capacity: 10
  }
  {
    name: 'dall-e-3'
    model: 'dall-e-3'
    version: '3.0'
    capacity: 1
  }
]

param tags = {
  Environment: 'dev'
  Project: 'az-llm'
}
