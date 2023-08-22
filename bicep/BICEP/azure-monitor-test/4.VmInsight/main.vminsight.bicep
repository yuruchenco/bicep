@description('Resource ID of the workspace.')
param workspaceResourceId string

@description('Location of the workspace.')
param workspaceLocation string

module VMISolutionDeployment './module.vminsight.bicep' = {
  name: 'VMISolutionDeployment'
  scope: resourceGroup(split(workspaceResourceId, '/')[2], split(workspaceResourceId, '/')[4])
  params: {
    workspaceLocation: workspaceLocation
    workspaceResourceId: workspaceResourceId
  }
}
