@description('Location of the workspace.')
param workspaceLocation string

@description('Resource ID of the workspace.')
param workspaceResourceId string

resource solution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  location: workspaceLocation
  name: 'VMInsights(${split(workspaceResourceId, '/')[8]})'
  properties: {
    workspaceResourceId: workspaceResourceId
  }
  plan: {
    name: 'VMInsights(${split(workspaceResourceId, '/')[8]})'
    product: 'OMSGallery/VMInsights'
    promotionCode: ''
    publisher: 'Microsoft'
  }
}
