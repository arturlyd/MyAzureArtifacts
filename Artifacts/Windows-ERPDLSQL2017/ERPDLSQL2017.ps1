<##################################################################################################

    Description
    ===========

	- This script does the following - 
		- Downloads SQL Server 2017 version that we install in QA tools. 
        it has its own license so we are not charged for that by Azure



    Usage examples
    ==============
    


##################################################################################################>
$StorageAccountName = "aqatoolslab2420"
$blobSas = "?sv=2017-11-09&ss=bfqt&srt=sco&sp=rwdlacup&se=2027-06-06T05:11:13Z&st=2018-06-05T21:11:13Z&spr=https,http&sig=vdilQIbevC02X6gu8d%2FQt25%2BUClG7FCRrchlogcFI2Q%3D"
$storageContext = New-AzureStorageContext $StorageAccountName -SasToken $blobSas
$containerName = "sqlserver"
$targetDir = 'c:\EpicorInstallers\'
$blobName = "en_sql_server_2017_standard_x64_dvd_11294407.iso"
$blobSSMS = "SSMS2017-Setup-ENU.exe"
$blobSSRS = "SQLServerReportingServices2017.exe"
$blobKey = "KeySQL2017.txt"
$blobIni = "MyConfigurationFileSQL2017.ini"
$SQLServerInstance = "(local)\SQL2017"
$SSRSInstallTargetPath = "C:\Program Files\Microsoft SQL Server Reporting Services"

if(!(Test-Path -Path $targetDir )){
    New-Item -ItemType directory -Path $targetDir
}
Get-AzureStorageBlobContent -Container $ContainerName -Blob $blobName -Destination ($targetDir + $blobName) -Context $StorageContext -Force #download SQL Server ISO
Get-AzureStorageBlobContent -Container $ContainerName -Blob $blobSSMS -Destination ($targetDir + $blobSSMS) -Context $StorageContext -Force #download SSMS exe
Get-AzureStorageBlobContent -Container $ContainerName -Blob $blobSSRS -Destination ($targetDir + $blobSSRS) -Context $StorageContext -Force #download SSRS exe
Get-AzureStorageBlobContent -Container $ContainerName -Blob $blobKey -Destination ($targetDir + $blobKey) -Context $StorageContext -Force #download SQL Server Serial Key
Get-AzureStorageBlobContent -Container $ContainerName -Blob $blobIni -Destination ($targetDir + $blobIni) -Context $StorageContext -Force #Download ini file for silent installation

#Installs SQL Server locally with standard settings for Developers/Testers.
# Install SQL from command line help - https://msdn.microsoft.com/en-us/library/ms144259.aspx
$sw = [Diagnostics.Stopwatch]::StartNew()
$currentUserName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name;
$SqlServerIsoImagePath = "$targetDir$blobName"

#Mount the installation media, and change to the mounted Drive.
$mountVolume = Mount-DiskImage -ImagePath $SqlServerIsoImagePath -PassThru
$driveLetter = ($mountVolume | Get-Volume).DriveLetter
$drivePath = $driveLetter + ":"
push-location -path "$drivePath"

#Install SQL Server locally
#.\Setup.exe /q /ACTION=Install /SUPPRESSPRIVACYSTATEMENTNOTICE="True" /IACCEPTROPENLICENSETERMS="True" /ENU="True" /QUIET="True" /FEATURES="SQLEngine,FullText,RS" LocalDB /UpdateEnabled /UpdateSource=MU /X86=false /INDICATEPROGRESS="False" /INSTANCENAME=SQL2016 /INSTALLSHAREDDIR="C:\Program Files\Microsoft SQL Server" /INSTALLSHAREDWOWDIR="C:\Program Files (x86)\Microsoft SQL Server" /INSTANCEID="SQL2016" /RSINSTALLMODE="DefaultNativeMode" /SQLSVCINSTANTFILEINIT="False" /INSTANCEDIR="C:\Program Files\Microsoft SQL Server" /AGTSVCACCOUNT="NT Service\SQLAgent$SQL2016" /AGTSVCSTARTUPTYPE="Manual" /COMMFABRICPORT="0" /COMMFABRICNETWORKLEVEL="0" /COMMFABRICENCRYPTION="0" /MATRIXCMBRICKCOMMPORT="0" /SQLSVCSTARTUPTYPE="Automatic" /SQLSYSADMINACCOUNTS=".\manager" /FILESTREAMLEVEL="0" /ENABLERANU="False" /SQLCOLLATION="SQL_Latin1_General_CP1_CI_AS" /SQLSVCACCOUNT="NT Service\MSSQL$SQL2016" /SECURITYMODE="SQL" /SQLTEMPDBFILECOUNT="1" /SQLTEMPDBFILESIZE="8" /SQLTEMPDBFILEGROWTH="64" /SQLTEMPDBLOGFILESIZE="8" /SQLTEMPDBLOGFILEGROWTH="64" /TCPENABLED="1" /NPENABLED="1" /BROWSERSVCSTARTUPTYPE="Automatic" /RSSVCACCOUNT="NT Service\ReportServer$SQL2016" /RSSVCSTARTUPTYPE="Automatic" /FTSVCACCOUNT="NT Service\MSSQLFDLauncher$SQL2016" /SAPWD="Epicor123" /SQLSYSADMINACCOUNTS="$currentUserName" /IACCEPTSQLSERVERLICENSETERMS
.\Setup.exe /ConfigurationFile="$targetDir$blobIni" 
#Dismount the installation media.
pop-location
Dismount-DiskImage -ImagePath $SqlServerIsoImagePath

#print Time taken to execute
$sw.Stop()
"Sql install script completed in {0:c}" -f $sw.Elapsed;

##################### Install SSRS ############################
$Parms = "/IAcceptLicenseTerms /PID=PHDV4-3VJWD-N7JVP-FGPKY-XBV89  /norestart /quiet"
Start-Process -FilePath $targetDir$blobSSRS -ArgumentList $Parms -Wait
##################### Install SSMS #############################
# Set file and folder path for SSMS installer .exe
$filepath="$targetDir$blobSSMS"
$Parms = " /Install /Quiet /Norestart /Logs log.txt"
Start-Process -FilePath $filepath -ArgumentList $Parms -Wait
<# 
#If SSMS not present, download
if (!(Test-Path $filepath)){
write-host "Downloading SQL Server 2017 SSMS..."
$URL = "https://download.microsoft.com/download/3/1/D/31D734E0-BFE8-4C33-A9DE-2392808ADEE6/SSMS-Setup-ENU.exe"
$clnt = New-Object System.Net.WebClient
$clnt.DownloadFile($url,$filepath)
}
#> 
##################  SSRS Configuration ##################
rsconfig -c -s $SQLServerInstance -d ReportServer -a SQL -u sa -p Epicor123 -i SSRS

function Get-ConfigSet()
{
	return Get-WmiObject -Namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin" `
		-class MSReportServer_ConfigurationSetting -ComputerName localhost
}

# Allow importing of sqlps module
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Retrieve the current configuration
$configset = Get-ConfigSet

$configset

If (! $configset.IsInitialized)
{
	# Get the ReportServer and ReportServerTempDB creation script
	[string]$dbscript = $configset.GenerateDatabaseCreationScript("ReportServer", 1033, $false).Script

	# Import the SQL Server PowerShell module
	Import-Module sqlps -DisableNameChecking | Out-Null

	# Establish a connection to the 
	$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection 
    $conn.ServerInstance = $SQLServerInstance
    $conn.LoginSecure = $FALSE
    $conn.Login = "sa"
    $conn.Password = "Epicor123"
    #Connect to the local, default instance of SQL Server
    $smo = new-object Microsoft.SqlServer.Management.Smo.Server($conn)
    
	# Create the ReportServer and ReportServerTempDB databases
	$db = $smo.Databases["master"]
	$db.ExecuteNonQuery($dbscript)
    
	# Set permissions for the databases
	$dbscript = $configset.GenerateDatabaseRightsScript($configset.WindowsServiceIdentityConfigured, "ReportServer", $false, $true).Script
    #$dbscript = $configset.GenerateDatabaseRightsScript("localhost\qatools", "ReportServer", $false, $false).Script
	$db.ExecuteNonQuery($dbscript)

	# Set the database connection info
	$configset.SetDatabaseConnection($SQLServerInstance, "ReportServer", 2, "", "")

	$configset.SetVirtualDirectory("ReportServerWebService", "ReportServer", 1033)
	$configset.ReserveURL("ReportServerWebService", "http://+:80", 1033)

	# Did the name change?
	$configset.SetVirtualDirectory("ReportServerWebApp", "Reports", 1033)
	$configset.ReserveURL("ReportServerWebApp", "http://+:80", 1033)

	$configset.InitializeReportServer($configset.InstallationID)

	# Re-start services?
	$configset.SetServiceState($false, $false, $false)
	Restart-Service $configset.ServiceName
	$configset.SetServiceState($true, $true, $true)

	# Update the current configuration
	$configset = Get-ConfigSet

	$configset.IsReportManagerEnabled
	$configset.IsInitialized
	$configset.IsWebServiceEnabled
	$configset.IsWindowsServiceEnabled
	$configset.ListReportServersInDatabase()
	$configset.ListReservedUrls();

	$inst = Get-WmiObject -Namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14" `
		-class MSReportServer_Instance -ComputerName localhost

	$inst.GetReportServerUrls()

}
