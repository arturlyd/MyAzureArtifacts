<##################################################################################################

    Description
    ===========

	- This script does the following - 
		- Downloads SQL Server 2016 version that we install in QA tools. 
        it has its own license so we are not charged for that by Azure

##################################################################################################>
[CmdletBinding()]
param(
    [string] $ssms = $true
)



$StorageAccountName = "aqatoolslab2420"
$blobSas = "?sv=2017-11-09&ss=bfqt&srt=sco&sp=rwdlacup&se=2027-06-06T05:11:13Z&st=2018-06-05T21:11:13Z&spr=https,http&sig=vdilQIbevC02X6gu8d%2FQt25%2BUClG7FCRrchlogcFI2Q%3D"
$storageContext = New-AzureStorageContext $StorageAccountName -SasToken $blobSas
$containerName = "sqlserver"
$targetDir = 'c:\EpicorInstallers\'
$blobName = "en_sql_server_2016_standard_x64_dvd_8701871.iso"
$blobSSMS = "SSMS2016-Setup-ENU.exe"
$blobIni = "MyConfigurationFileSQL2016.ini"

#Make sure the installers directory exists so subsequent scripts can access the location without issues.
$targetDir = "c:\EpicorInstallers\"
$Logfile = ($targetDir + "ERPDLSQL2016.log")
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
    Write-Host ((Get-Date).ToString()+ ": " +$logstring)
}
Remove-Item $Logfile -ErrorAction SilentlyContinue

try {
    if(!(Test-Path -Path $targetDir )){
        New-Item -ItemType directory -Path $targetDir
    }
    Get-AzureStorageBlobContent -Container $ContainerName -Blob $blobName -Destination ($targetDir + $blobName) -Context $StorageContext -Force #download SQL Server ISO
    Get-AzureStorageBlobContent -Container $ContainerName -Blob $blobSSMS -Destination ($targetDir + $blobSSMS) -Context $StorageContext -Force #download SSMS exe
    Get-AzureStorageBlobContent -Container $ContainerName -Blob $blobIni -Destination ($targetDir + $blobIni) -Context $StorageContext -Force #Download ini file for silent installation
}
catch
{
    LogError
    break
}
try {
    #Installs SQL Server locally with standard settings for Developers/Testers.
    # Install SQL from command line help - https://msdn.microsoft.com/en-us/library/ms144259.aspx
    $sw = [Diagnostics.Stopwatch]::StartNew()
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
       
}
catch
{
    LogError
    break
}
finally 
{
    #Remove SQL Server ISO
    Remove-Item -Path $SqlServerIsoImagePath -ErrorAction SilentlyContinue
}
if($ssms -eq $true)
{
    try{
        #If SSMS not present, download
        <#if (!(Test-Path $filepath)){
        write-host "Downloading SQL Server 2016 SSMS..."
        $URL = "https://download.microsoft.com/download/3/1/D/31D734E0-BFE8-4C33-A9DE-2392808ADEE6/SSMS-Setup-ENU.exe"
        $clnt = New-Object System.Net.WebClient
        $clnt.DownloadFile($url,$filepath)
        Write-Host "SSMS installer download complete" -ForegroundColor Green
    
        }
        else {
    
        write-host "Located the SQL SSMS Installer binaries, moving on to install..."
        }#>
    
        # start the SSMS installer
        write-host "Beginning SSMS 2016 install..." -nonewline
        $Parms = " /Install /Quiet /Norestart /Logs log.txt"
        Start-Process -FilePath $targetDir$blobSSMS -ArgumentList $Parms -Wait
    }
    catch
    {
        LogError
        break
    }
    finally 
    {
        #Remove SSMS Installer
        Remove-Item -Path $targetDir$blobSSMS -ErrorAction SilentlyContinue
    }
}