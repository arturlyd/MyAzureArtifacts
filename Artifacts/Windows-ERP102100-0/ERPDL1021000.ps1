<##################################################################################################

    Description
    ===========

	- This script does the following - 
		- Downloads ERP 10.2.100.0 and its demo database



    Usage examples
    ==============
    


##################################################################################################>
$StorageAccountName = "aqatoolslab2420"
$blobSas = "?sv=2017-11-09&ss=bfqt&srt=sco&sp=rwdlacup&se=2027-06-06T05:11:13Z&st=2018-06-05T21:11:13Z&spr=https,http&sig=vdilQIbevC02X6gu8d%2FQt25%2BUClG7FCRrchlogcFI2Q%3D"
$storageContext = New-AzureStorageContext $StorageAccountName -SasToken $blobSas
$containerName = "isos"
$targetDir = 'c:\EpicorInstallers\'
$blobName = "RL10.2.100.0.iso"
if(!(Test-Path -Path $targetDir )){
    New-Item -ItemType directory -Path $targetDir
}
Get-AzureStorageBlobContent -Container $ContainerName -Blob $blobName -Destination ($targetDir + $blobName) -Context $StorageContext -Force
$blobName = "Demo321000B5.bak"
Get-AzureStorageBlobContent -Container $ContainerName -Blob $blobName -Destination ($targetDir + $blobName) -Context $StorageContext -Force