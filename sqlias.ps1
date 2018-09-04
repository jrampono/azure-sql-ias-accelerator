# Configuration Variables
$Configs = (Get-Content 'C:\Jrambo\Git\WorkMS\SQL IAS Powershell\Config.json' | Out-String | ConvertFrom-Json)


## Global
$Location =  $Configs.Globals.Location
$ResourceGroupName = $Configs.Globals.ResourceGroupName

## Storage
$StorageName = $Configs.Globals.ResourceGroupName + "storage"
$StorageSku = $Configs.Storage.StorageSku
$DataDiskSize = $Configs.Storage.DataDiskSize
$DataDiskSku = $Configs.Storage.DataDiskSku

## Network
$InterfaceName = $ResourceGroupName + "ServerInterface"
$NsgName = $ResourceGroupName + "nsg"
$VNetName = $ResourceGroupName + "VNet"
$SubnetName = $Configs.Network.SubnetName
$VNetAddressPrefix = $Configs.Network.VNetAddressPrefix
$VNetSubnetAddressPrefix = $Configs.Network.VNetSubnetAddressPrefix
$TCPIPAllocationMethod = $Configs.Network.TCPIPAllocationMethod
$DomainName = $ResourceGroupName

##Compute
#$VMName = $ResourceGroupName
$VMName = $Configs.Compute.VMName
$ComputerName =  $Configs.Compute.ComputerName
$VMSize = $Configs.Compute.VMSize
$OSDiskName = $VMName + "OSDisk"
$DataDiskName = $VMName + "DataDisk"

##Image
$PublisherName = $Configs.Image.PublisherName
$OfferName = $Configs.Image.OfferName
$Sku = $Configs.Image.Sku
$Version = $Configs.Image.Version


##Post Deployment Script Details 
$ScriptStorageAccountName = $Configs.PostDeploymentScript.ScriptStorageAccountName
$ScriptStorageAccountKey = $Configs.PostDeploymentScript.ScriptStorageAccountKey

#Login to Azure 
Login-AzureRmAccount 

#Set Subscription
Set-AzureRmContext -SubscriptionId $Configs.Globals.SubscriptionId


# Resource Group
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

# Storage
$StorageAccount = New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -SkuName $StorageSku -Kind "Storage" -Location $Location

# Network
$SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
$VNet = New-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
$PublicIp = New-AzureRmPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod $TCPIPAllocationMethod -DomainNameLabel $DomainName
$NsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name "RDPRule" -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
$NsgRuleSQL = New-AzureRmNetworkSecurityRuleConfig -Name "MSSQLRule"  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 1433 -Access Allow
$Interface = New-AzureRmNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PublicIp.Id -NetworkSecurityGroupId $Nsg.Id

# Compute
$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
$secpasswd = ConvertTo-SecureString $Configs.Compute.AdminPassword -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($Configs.Compute.AdminUser, $secpasswd)
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate #-TimeZone = $TimeZone
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id

# Image
$VirtualMachine = Set-AzureRmVMSourceImage -VM $VirtualMachine -PublisherName $PublisherName -Offer $OfferName -Skus $Sku -Version $Version 

#Create Storage Pools in Azure 
$diskConfig = New-AzureRmDiskConfig -Location  $Location -CreateOption Empty -DiskSizeGB $DataDiskSize -Sku $DataDiskSku
#Data Disks (6) 
For ($i=0; $i -le 5; $i++) {
    $DataDiskNameTemp = $DataDiskName + $i
    New-AzureRmDisk -ResourceGroupName $ResourceGroupName -DiskName $DataDiskNameTemp -Disk $diskConfig    
   }

#Log Disks (3) 
For ($i=0; $i -le 2; $i++) {
    $LogDiskName = $DataDiskName + "Log" + $i
    New-AzureRmDisk -ResourceGroupName $ResourceGroupName -DiskName $LogDiskName -Disk $diskConfig    
   }

   
#TempDB Disks (4) 
For ($i=0; $i -le 3; $i++) {
    $TempDBDiskName = $DataDiskName + "TempDB" + $i
    New-AzureRmDisk -ResourceGroupName $ResourceGroupName -DiskName $TempDBDiskName -Disk $diskConfig    
   }


#$VirtualMachine = Get-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName
$Disks = Get-AzureRmDisk -ResourceGroupName $ResourceGroupName  

For ($i=0; $i -lt $Disks.Length; $i++) {
    Add-AzureRmVMDataDisk -CreateOption Attach -Lun $i -ManagedDiskId $Disks[$i].Id  -VM $VirtualMachine -Name $Disks[$i].Name
   }


# Create the VM in Azure
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine -Verbose

#Update-AzureRmVM -VM $VirtualMachine -ResourceGroupName $ResourceGroupName 

# Add the SQL IaaS Extension 
Set-AzureRmVMSqlServerExtension -ResourceGroupName $ResourceGroupName -VMName $VMName -name "SQLIaasExtension" -version "1.2" -Location $Location


Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName -Location $Location -VMName $VMName -Name "ContosoTest" -TypeHandlerVersion "1.1" -StorageAccountName $ScriptStorageAccountName -FileName "extensionscript.ps1" -ContainerName "scripts" -StorageAccountKey $ScriptStorageAccountKey


# Set Caching Mode
$VirtualMachine = Get-AzureRmVM -ResourceGroupName $ResourceGroupName  -Name $VMName

For ($i=0; $i -le 13; $i++) {
    Set-AzureRmVMDataDisk -VM $VirtualMachine -Lun $i -Caching ReadOnly 
   }

Update-AzureRmVM -ResourceGroupName $ResourceGroupName -VM $VirtualMachine

#Diskspd.exe -b4K -d60 -h -o128 -t32 -si -c50000M e:\io.dat

#Get-AzureRMVMImagePublisher -Location $Location | Select PublisherName
#Get-AzureRMVMImageOffer -Location $Location -Publisher $PublisherName | Select Offer
#Get-AzureRMVMImageSku -Location $Location -Publisher $PublisherName -Offer $OfferName | Select Skus
#Get-AzureRMVMImage -Location $Location -Publisher $PublisherName -Offer $OfferName -Sku $Sku | Select Version
#Remove-AzureRmResourceGroup -Name $ResourceGroupName

