<##################################################################################################

    Description
    ===========

	- This script does the following -
        - Installs PS.ERP/Core modules for Choco instructions
		- Downloads ERP 10.2.200.0 and its demo database
        - Creates Certificate
        - Creates a new appserver
        - Install license
        - Runs Conversions



##################################################################################################>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $onetwo = "one",
    [Parameter(Mandatory = $true)]
    [string] $checkbx = $true
 )

##################################################

$StorageAccountName = "aqatoolslab2420"
$blobUri = "https://aqatoolslab2420.blob.core.windows.net/"
$blobSas = "sv=2017-11-09&ss=bfqt&srt=sco&sp=rwdlacup&se=2027-06-06T05:11:13Z&st=2018-06-05T21:11:13Z&spr=https,http&sig=vdilQIbevC02X6gu8d%2FQt25%2BUClG7FCRrchlogcFI2Q%3D"
$storageContext = New-AzureStorageContext $StorageAccountName -SasToken ("?"+$blobSas)
$containerName = "isos"
$licContainerName = "licenses"
$targetDir = "c:\EpicorInstallers\"
$logfilesdir = "C:\temp"
$dbBackup = "Demo32200Build6.bak"
$targetSqlUser = "sa"
$targetSqlPassword = "Epicor123"
$defaultWebSiteName = "Default Web Site"
$computerName = $env:ComputerName
$Logfile = ($targetDir + "ERPDL1022000.log")
$erpVersion = "10.2.200"
$erpPatch = ".9"
$epicorGSM = "epicor"
$epicorPass = "epicor"
$apppoolUserName = "$env:ComputerName\$env:USERNAME"
$erpBinding = "HttpsBinaryUsernameChannel"
$appServerName = "ERP102200"
$sqlDataSource = [System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources()|Where-Object{$_.ServerName -eq $env:COMPUTERNAME}
$sqlInstance = $sqlDataSource.ServerName + "\" +  $sqlDataSource.InstanceName
$sqlFilesLoc = "c:\SQLFiles\"
$ssrsDBName = "SSRS"
$ssrsServerInstallPath = "C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer"
$ssrsBaseURL = "http://$env:ComputerName/ReportServer"
$licenseID = "115506.lic"
$erpInstallPatch = "C:\Epicor\Erp10\" #pending to be supported

if(!(Test-Path -Path $targetDir )){
    New-Item -ItemType directory -Path $targetDir
}
function LogError {
    $exceptionObject = $_.Exception
    $exceptionData = "$($exceptionObject.Message)"
    $invokationInfo = $_.InvocationInfo
    $invokationData = "@ $($invokationInfo.PositionMessage) `r`n FullLine $($invokationInfo.Line)"
    $formattedError = "$($exceptionData) `r`n $($invokationData)"
    LogWrite("There was an error: $formattedError")
}
Function LogWrite ([string]$logstring)
{
    Add-content $Logfile -value ((Get-Date).ToString()+ ": " +$logstring)
}
Remove-Item $Logfile -ErrorAction SilentlyContinue

    ############# Install Chocolatey ###################
    LogWrite ("ONE Test onetwo: " + $onetwo)
    LogWrite ("ONE Test checkbx: " + $checkbx)
