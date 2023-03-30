//Virtual Machine
param location string
param spokeVnetName string
param vmSubnetName string
param logAnalyticsWorkspaceName string
param principalId string

// Tag values
var TAG_VALUE = {
  CostCenterNumber: '10181378'
  CreateDate: '2023/03/23'
  Location: 'japaneast'
  Owner: 'akkoike'
  }

 // VM variables
var vmName = 'vm1'
var adminUsername = 'azureuser'
var adminPassword = 'P@ssw0rd1234'
var vmSize = 'Standard_D2s_v3'
var vmImagePublisher = 'Canonical'
var vmImageOffer = 'UbuntuServer'
var vmImageSku = '18.04-LTS'
var vmImageVersion = 'latest'
var vmNicName = '${vmName}-nic'
var vmStorageAccountContainerName = 'vhds'
var vmStorageAccountType = 'Standard_LRS'
var vmOSDiskName = '${vmName}-osdisk'
var vmDataDiskName = '${vmName}-datadisk'
var vmDataDiskSize = 1023
var vmDataDiskCaching = 'ReadWrite'




// Reference to the log analytics workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' existing = {
  name: logAnalyticsWorkspaceName
}

// Reference the existing SpokeVNET
resource existingspokevnet 'Microsoft.Network/virtualNetworks@2020-05-01' existing = {
  name: spokeVnetName
  resource existingvmsubnet 'subnets' existing = {
    name: vmSubnetName
  }
}
  // RBAC Configuration
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  //scope: subscription()
  // Owner
  //name: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
  // Contributer
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  // Reader
  //name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

// RBAC assignment
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(vm.id, principalId, contributorRoleDefinition.id)
  scope: vm
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: principalId
    principalType: 'User'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: vmNicName
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

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: vmName
  location: location
  tags:TAG_VALUE
  properties:{
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: vmImagePublisher
        offer: vmImageOffer
        sku: vmImageSku
        version: vmImageVersion
      }
      osDisk: {
        name: vmOSDiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: vmStorageAccountType
        }
        diskSizeGB: 30
      }
      dataDisks: [
        {
          name: vmDataDiskName
          createOption: 'Empty'
          caching: vmDataDiskCaching
          diskSizeGB: vmDataDiskSize
          lun: 0
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
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
  }
}

//Deploy diagnostic settings
resource diagnosticvm 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${vmName}-diagnostic'
  scope: vm
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'AllLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    metrics:[
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}

output OUTPUT_VM_NAME string = vm.name
output OUTPUT_NIC_NAME string = nic.name
