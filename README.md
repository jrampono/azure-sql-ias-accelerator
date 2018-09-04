# azure-sql-ias-accelerator
Powershell Script to Assist with IAS SQL Deployments

## Instructions

1. Create an Azure Storage Account and container and upload the file "extensionscript.ps1" to it. This is the post deployment script that will customise the VM image after it is provisioned. 

2. Update the Config.json file with your specific configuration settings. Use (https://docs.microsoft.com/en-us/powershell/module/azurerm.compute/get-azurermvmimageoffer?view=azurermps-6.8.1)[Get-AzureMVMImageOffer] to list all available images. Also be sure to use (https://docs.microsoft.com/en-us/powershell/module/azurerm.compute/get-azurermvmimage?view=azurermps-6.8.1)[Get-AzuremVmImages] to get a list of the valid versions associated with your offer. 

For example: 
```
Get-AzureRmVMImageOffer -Location "Australia SouthEast" -PublisherName "MicrosoftSQLServer"
```

To enable AHUB use the offers with "BYOL" in the name. Current offer list in Australia SE is 
+ SQL2008R2SP3-WS2008R2SP1 
+ SQL2012SP3-WS2012R2      
+ SQL2012SP3-WS2012R2-BYOL 
+ SQL2012SP4-WS2012R2      
+ SQL2012SP4-WS2012R2-BYOL 
+ SQL2014SP1-WS2012R2-BYOL 
+ SQL2014SP2-WS2012R2      
+ SQL2014SP2-WS2012R2-BYOL 
+ SQL2016-WS2012R2         
+ SQL2016-WS2012R2-BYOL    
+ SQL2016-WS2016           
+ SQL2016SP1-WS2012R2      
+ SQL2016SP1-WS2016        
+ SQL2016SP1-WS2016-BYOL   
+ SQL2016SP2-WS2016        
+ SQL2016SP2-WS2016-BYOL   
+ SQL2017-RHEL7            
+ SQL2017-RHEL73           
+ SQL2017-SLES12SP2        
+ SQL2017-Ubuntu1604       
+ SQL2017-WS2016           
+ SQL2017-WS2016-BYOL       

3. Open the primary powershell script "sqlias.ps1". Change "{Path to your config file}" to the actual full path of your config file. 

4. Run "sqlias.ps1"

## Code of Conduct
This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## License
These samples and templates are all licensed under the MIT license. See the license.txt file in the root.


