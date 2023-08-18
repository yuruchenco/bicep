//Virtual Machine
param location string
param spokeVnetName string
param vmSubnetName string
param vmNumber int
param zonenumber string
param straccUri string
param straccvmdiagid string
param straccvmdiagname string
param resourceGroupName string

var accountSasProperties = {
  default: {
    signedServices: 'b'
    signedPermission: 'r'
    signedExpiry: '2020-08-20T11:00:00Z'
    signedResourceTypes: 's'
  }
}

// Tag values
var TAG_VALUE = {
  CostCenterNumber: '10181378'
  CreateDate: '2023/03/23'
  Location: 'japaneast'
  Owner: 'akkoike'
  }

 // VM variables
var VM_NAME = 'vm${vmNumber}'
var VM_MAIN_NAME = '${VM_NAME}-poc-main-stag-001'
var ADMIN_USERNAME = 'azureuser'
var ADMIN_PASSWORD = 'P@ssw0rd1234'
var VM_SIZE = 'Standard_B1s'
var VM_IMAGE_PUBLISHER = 'Canonical'
var VM_IMAGE_OFFER = 'UbuntuServer'
var VM_IMAGE_SKU = '18.04-LTS'
var VM_IMAGE_VERSION = 'latest'
var VM_NIC_NAME = 'nic-poc-${VM_NAME}-stag-001'
var OS_MANAGED_DISK_REDUNDANCY = 'Standard_LRS'
var DATA_MANAGED_DISK_REDUNDANCY = 'StandardSSD_LRS'
var VM_OS_DISK_NAME = 'osdisk-poc-${VM_NAME}-stag-001'
var OS_DATA_DISK_CACHING = 'ReadWrite'
var VM_DATA_DISK_NAME = 'datadisk-poc-${VM_NAME}-stag-001'
var VM_DATA_DISK_SIZE = 1023
var VM_DATA_DISK_CACHING = 'ReadOnly'
var VM_RECOVERY_SERVICES_VAULT_NAME = 'rsv-${VM_NAME}-stag-001'
var vaultName = '${VM_RECOVERY_SERVICES_VAULT_NAME}-vault'
var backupFabric = 'Azure'
var backupPolicyName = 'DefaultPolicy'
var protectionContainer = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroupName};${VM_MAIN_NAME}'
var protectedItem = 'vm;iaasvmcontainerv2;${resourceGroupName};${VM_MAIN_NAME}'



// Reference to the log analytics workspace
// resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' existing = {
//   name: logAnalyticsWorkspaceName
// }

// Reference the existing SpokeVNET
resource existingspokevnet 'Microsoft.Network/virtualNetworks@2020-05-01' existing = {
  name: spokeVnetName
  resource existingvmsubnet 'subnets' existing = {
    name: vmSubnetName
  }
}

// Reference the existing Storage Account
resource existingstorageaccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: straccvmdiagname
}
  // RBAC Configuration
// resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
//   //scope: subscription()
//   // Owner
//   //name: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
//   // Contributer
//   name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
//   // Reader
//   //name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
// }

// RBAC assignment
// resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//   name: guid(vm.id, principalId, contributorRoleDefinition.id)
//   scope: vm
//   properties: {
//     roleDefinitionId: contributorRoleDefinition.id
//     principalId: principalId
//     principalType: 'User'
//   }
// }

//Deploy nic
resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: VM_NIC_NAME
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: existingspokevnet::existingvmsubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

//Deploy vm
resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: VM_MAIN_NAME
  location: location
  tags:TAG_VALUE
  zones: [ zonenumber ]
  properties:{
    hardwareProfile: {
      vmSize: VM_SIZE
    }
    diagnosticsProfile:{
      bootDiagnostics:{
        enabled: true
        storageUri: straccUri
      }
    }
    storageProfile: {
      imageReference: {
        publisher: VM_IMAGE_PUBLISHER
        offer: VM_IMAGE_OFFER
        sku: VM_IMAGE_SKU
        version: VM_IMAGE_VERSION
      }
      osDisk: {
        name: VM_OS_DISK_NAME
        createOption: 'FromImage'
        caching: OS_DATA_DISK_CACHING
        managedDisk: {
          storageAccountType: OS_MANAGED_DISK_REDUNDANCY
        }
        diskSizeGB: 30
      }
      dataDisks: [
        {
          name: VM_DATA_DISK_NAME
          createOption: 'Empty'
          caching: VM_DATA_DISK_CACHING
          diskSizeGB: VM_DATA_DISK_SIZE
          lun: 0
          managedDisk:{
            storageAccountType: DATA_MANAGED_DISK_REDUNDANCY
          }
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile:{
      computerName: VM_MAIN_NAME
      adminUsername: ADMIN_USERNAME
      adminPassword: ADMIN_PASSWORD
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
  }
}

//Deploy vm extension DependencyAgent
resource vmExtensionDependencyAgent 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  name: '${VM_NAME}-DependencyAgent'
  parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.10'
    autoUpgradeMinorVersion: true
    settings: {
      enableAMA: true
    }
    protectedSettings: {}
  }
}

//Deploy vm extension AzureMonitorForLinux
resource vmExtensionAzureMonitorForLinux 'Microsoft.Compute/virtualMachines/extensions@2022-11-01' = {
  name: '${VM_NAME}AzureMonitorForLinux'
  parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.21'
    autoUpgradeMinorVersion: true
  }
}

//Deploy recovery services vault
// resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-02-01' = {
//   name: vaultName
//   location: location
//   sku: {
//       name: 'RS0'
//       tier: 'Standard'
//   }
//   properties: {}
// }

// //Deploy backup policy
// resource vaultName_backupFablic_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2022-02-01' = {
//   name: '${vaultName}/${backupFabric}/${protectionContainer}/${protectedItem}'
//   properties: {
//     protectedItemType: 'Microsoft.Compute/virtualMachines'
//     policyId: '${recoveryServicesVault.id}/backupPolicies/${backupPolicyName}'
//     sourceResourceId: vm.id
//   }
// }

// Deploy the Storage Account for VMDiag
resource teststorageaccountvmdiag 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: 'testdiag${uniqueString(resourceGroup().id)}'
  location: location
  tags: TAG_VALUE
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

//Deploy vm diagnostics
resource vmDiagnostic 'Microsoft.Compute/virtualMachines/extensions@2017-12-01' = {
  name: '${VM_NAME}-vmDiagnostic'
  parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Diagnostics'
    type: 'LinuxDiagnostic'
    typeHandlerVersion: '3.0'
    autoUpgradeMinorVersion: false
    settings: {
      strageAccount: teststorageaccountvmdiag.name
    }
      protectedSettings: {
        storageAccountName: teststorageaccountvmdiag.name
        storageAccountEndPoint: 'https://core.windows.net'
        storageAccountSasToken: [listAccountSas(teststorageaccountvmdiag.name,'2021-04-01', {
          signedServices: 'b'
          signedPermission: 'rw'
          signedExpiry: '2122-08-20T11:00:00Z'
          signedResourceTypes: 'o'
        }).accountSasToken]
        //storageAccountKey: [listKeys(resourceId('Microsoft.Storage/storageAccounts', existingstorageaccount.name), '2021-04-01').keys[0].value]
      }
  }
}


// vmInsights collection rules
// resource vmInsightsCollectionRules 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
//   name: '${VM_NAME}-vmInsightsCollectionRules'
//   location: location
//   kind:'Linux'
//   properties:{
//     dataSources:{
//       performanceCounters:[
//         {
//           name:'VMInsightsPerCounters'
//           streams:[
//             'Microsoft-InsightsMetrics'
//           ]
//           samplingFrequencyInSeconds:60
//           counterSpecifiers:[
//             '\\VMInsight\\%DetailMetrics'
//           ]
//         }
//       ]
//       extensions:[
//         {
//           streams:[
//             'Microsoft-ServiceMap'
//           ]
//           extensionName:'DependencyAgent'
//           name:'DependencyAgentDataSource'
//         }
//       ]
//     }
//     destinations:{
//       logAnalytics:[
//         {
//         workspaceResourceId:logAnalyticsWorkspace.id
//         name: 'lab-je-log'
//       }
//     ]
//   }
//   dataFlows:[
//     {
//       streams:[
//         'Microsoft-InsightsMetrics'
//       ]
//       destinations:[
//         'lab-je-log'
//       ]
//     }
//     {
//       streams:[
//         'Microsoft-ServiceMap'
//       ]
//       destinations:[
//         'lab-je-log'
//       ]
//     }
//   ]
// }
// }

//Deploy diagnostic settings
// resource diagnosticvm 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   name: '${vmName}-diagnostic'
//   scope: vm
//   properties: {
//     workspaceId: logAnalyticsWorkspace.id
//     logs: [
//       {
//         category: 'AllLogs'
//         enabled: true
//         retentionPolicy: {
//           enabled: true
//           days: 30
//         }
//       }
//     ]
//     metrics:[
//       {
//         category: 'AllMetrics'
//         enabled: true
//         retentionPolicy: {
//           enabled: true
//           days: 30
//         }
//       }
//     ]
//   }
// }

output OUTPUT_VM_NAME string = vm.name
output OUTPUT_NIC_NAME string = nic.name
