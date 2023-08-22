@description('VM Resource ID.')
param VmResourceId string

@description('The Virtual Machine Location.')
param VmLocation string

@description('OS Type, Example: Linux / Windows')
param osType string

@description('Workspace Resource ID.')
param WorkspaceResourceId string

var VmName = split(VmResourceId, '/')[8]
var DaExtensionName = ((toLower(osType) == 'windows') ? 'DependencyAgentWindows' : 'DependencyAgentLinux')
var DaExtensionType = ((toLower(osType) == 'windows') ? 'DependencyAgentWindows' : 'DependencyAgentLinux')
var DaExtensionVersion = '9.5'
var MmaExtensionName = ((toLower(osType) == 'windows') ? 'MMAExtension' : 'OMSExtension')
var MmaExtensionType = ((toLower(osType) == 'windows') ? 'MicrosoftMonitoringAgent' : 'OmsAgentForLinux')
var MmaExtensionVersion = ((toLower(osType) == 'windows') ? '1.0' : '1.4')


resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: VmName
  location: VmLocation
}

resource daExtension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  parent: vm
  name: DaExtensionName
  location: VmLocation
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: DaExtensionType
    typeHandlerVersion: DaExtensionVersion
    autoUpgradeMinorVersion: true
  }
}

resource mmaExtension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  parent: vm
  name: MmaExtensionName
  location: VmLocation
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: MmaExtensionType
    typeHandlerVersion: MmaExtensionVersion
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(WorkspaceResourceId, '2021-12-01-preview').customerId
      azureResourceId: VmResourceId
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(WorkspaceResourceId, '2021-12-01-preview').primarySharedKey
    }
  }
}
