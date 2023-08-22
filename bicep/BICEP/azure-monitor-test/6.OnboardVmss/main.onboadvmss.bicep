@description('VM Resource ID.')
param VmssResourceId string

@description('The Virtual Machine Location.')
param VmssLocation string

@description('OS Type, Example: Linux / Windows')
param osType string

@description('Workspace Resource ID.')
param WorkspaceResourceId string

var VmssNamevar = split(VmssResourceId, '/')[8]
var DaExtensionName = ((toLower(osType) == 'windows') ? 'DependencyAgentWindows' : 'DependencyAgentLinux')
var DaExtensionType = ((toLower(osType) == 'windows') ? 'DependencyAgentWindows' : 'DependencyAgentLinux')
var DaExtensionVersion = '9.5'
var MmaExtensionName = ((toLower(osType) == 'windows') ? 'MMAExtension' : 'OMSExtension')
var MmaExtensionType = ((toLower(osType) == 'windows') ? 'MicrosoftMonitoringAgent' : 'OmsAgentForLinux')
var MmaExtensionVersion = ((toLower(osType) == 'windows') ? '1.0' : '1.4')

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2021-11-01' = {
  name: VmssNamevar
  location: VmssLocation
  properties:{}
}

resource daExtension 'Microsoft.Compute/virtualMachineScaleSets/extensions@2018-10-01' = {
  parent: vmss
  name: DaExtensionName
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: DaExtensionType
    typeHandlerVersion: DaExtensionVersion
    autoUpgradeMinorVersion: true
  }
}

resource mmaExtension 'Microsoft.Compute/virtualMachineScaleSets/extensions@2018-10-01' = {
  parent: vmss
  name: MmaExtensionName
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: MmaExtensionType
    typeHandlerVersion: MmaExtensionVersion
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: reference(WorkspaceResourceId, '2021-12-01-preview').customerId
      azureResourceId: VmssResourceId
      stopOnMultipleConnections: true
    }
    protectedSettings: {
      workspaceKey: listKeys(WorkspaceResourceId, '2021-12-01-preview').primarySharedKey
    }
  }
}
