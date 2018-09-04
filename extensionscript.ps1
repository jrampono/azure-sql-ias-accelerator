$PoolCount = Get-PhysicalDisk -CanPool $True

$Subsystem = Get-StorageSubSystem

$DataStoragePool = New-StoragePool -FriendlyName "DataFiles" -StorageSubsystemFriendlyName $Subsystem.FriendlyName -PhysicalDisks $PoolCount 



$VirtualDisk = New-VirtualDisk -StoragePoolUniqueId  $DataStoragePool.UniqueId -FriendlyName "DataFiles" -Interleave 65536 -NumberOfColumns $PoolCount.Length -ResiliencySettingName simple -UseMaximumSize

Initialize-Disk -PartitionStyle GPT -PassThru -VirtualDisk $VirtualDisk 

$VirtualDisk = Get-VirtualDisk -FriendlyName "DataFiles"

$Partition = New-Partition -AssignDriveLetter -UseMaximumSize -DiskId $VirtualDisk.UniqueId 

Format-Volume -FileSystem NTFS -NewFileSystemLabel "DataDisks" -AllocationUnitSize 65536 -Confirm:$false -Partition $Partition

#Remove-VirtualDisk "DataFiles"
#Remove-StoragePool -FriendlyName "DataFiles"