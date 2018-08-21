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


##################################################
$password = ConvertTo-SecureString "Epicor123" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:USERDOMAIN\qatools", $password)

Invoke-Command -Credential $credential -ComputerName $env:COMPUTERNAME -ScriptBlock{

$StorageAccountName = "aqatoolslab2420"
$blobUri = "https://aqatoolslab2420.blob.core.windows.net/"
$blobSas = "sv=2017-11-09&ss=bfqt&srt=sco&sp=rwdlacup&se=2027-06-06T05:11:13Z&st=2018-06-05T21:11:13Z&spr=https,http&sig=vdilQIbevC02X6gu8d%2FQt25%2BUClG7FCRrchlogcFI2Q%3D"
$storageContext = New-AzureStorageContext $StorageAccountName -SasToken ("?"+$blobSas)
$containerName = "isos"
$licContainerName = "licenses"
$targetDir = "c:\EpicorInstallers\"
$logfilesdir = "$targetDir\logfiles"
$dbBackup = "Demo32200Build6.bak" 
$targetSqlUser = "sa"
$targetSqlPassword = "Epicor123"
$defaultWebSiteName = "Default Web Site"
$computerName = $env:ComputerName
$erpVersion = "10.2.200"
$erpPatch = ".11"
$epicorGSM = "epicor"
$epicorPass = "epicor"
$apppoolUserName = "$env:ComputerName\$env:USERNAME"
$erpBinding = "HttpsBinaryUsernameChannel"
$appServerName = "ERP102200"
$sqlDataSource = [System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources()|Where-Object{$_.ServerName -eq $env:COMPUTERNAME}
$sqlInstance = $sqlDataSource.ServerName + "\" +  $sqlDataSource.InstanceName
$sqlFilesLoc = "c:\SQLFiles\"
$ssrsDBName = "SSRS"
$ssrsBaseURL = "http://$env:ComputerName/ReportServer"
$licenseID = "115506.lic"
$erpInstallPatch = "C:\Epicor\Erp10\" #pending to be supported

$Logfile = ("$targetDir\logfiles\" + "ERP10.2.200.log")
if(!(Test-Path -Path "$targetDir\logfiles" )){
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

    ############# Install Chocolatey ###################
    LogWrite ("############# Install Chocolatey ###################")
    try{
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        choco feature enable -n allowGlobalConfirmation
    }
    catch
    {
        LogError
        break
    }
    ############# Import PS Modules ###################
    #modules must be installed in one of these paths: [System.Environment]::GetEnvironmentVariable("PSModulePath")
    LogWrite ("############# Import PS Modules ###################")
    try{
        choco upgrade epicorpserp -s "https://epicor-corp.pkgs.visualstudio.com/_packaging/CNA/nuget/v2/" -u "epicor" `
                                -p "ilxf6um6qfqk7ikel5jipldvvfndjmzny63f3cl72b7exnpqt2hq" --force
        Import-Module Epicor.Ps.Erp -DisableNameChecking
    }
    catch
    {
        LogError
        break
    }

    ######### Remove default Azure certificate and create a new one ################
    LogWrite ("######### Remove default Azure certificate and create a new one ################")
    #https://blogs.technet.microsoft.com/vishalagarwal/2009/08/21/generating-a-certificate-self-signed-using-powershell-and-certenroll-interfaces/
    write-host "######### Remove default Azure certificate and create a new one ################" -ForegroundColor Green
    try{
        LogWrite ("Remove default Certificate")
        $Store = New-Object Security.Cryptography.X509Certificates.X509Store(
            "\\$computerName\My",
            [Security.Cryptography.X509Certificates.StoreLocation]::LocalMachine)
        $Store.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
        $Store.Certificates |
        ForEach-Object { $Store.Remove($_) }

        LogWrite ("Creates new Certificate")
        $erpCert = New-SelfSignedCertificate -FriendlyName $computerName -DnsName $computerName -CertStoreLocation "cert:\LocalMachine\My"
        Export-Certificate -Cert $erpCert -FilePath ($targetDir + $computerName + ".cer")
        $certFile = ( Get-ChildItem -Path ($targetDir + $computerName + ".cer"))
        $certFile | Import-Certificate -CertStoreLocation cert:\LocalMachine\Root
        #Add HTTPS binding to IIS
        LogWrite ("Adds HTTPs binding to defatul website and sets certificate")
        if($null -eq (Get-WebBinding -Name $defaultWebSiteName -Port 443 -Protocol "https")){
            New-WebBinding -Name $defaultWebSiteName -IP "*" -Port 443 -Protocol https
        }
        (Get-WebBinding -Name $defaultWebSiteName -Port 443 -Protocol "https").AddSslCertificate($erpCert.GetCertHashString(), "my")
        $Store.Close()
    }
    catch
    {
        LogError
        break
    }

    ############ Restore Demo database ###############
    LogWrite ("############ Restore Demo database ###############")
    write-host "############ Restore Demo database ###############" -ForegroundColor Green
    try{
        $targetDBName = $appServerName

        if(!(Test-Path -Path $sqlFilesLoc )){
            New-Item -ItemType directory -Path $sqlFilesLoc
        }
        $sqlBackupLocation = "$targetDir$dbBackup"
        if(!(Test-Path -Path $targetDir )){
            throw ("DB Backup path not found: " + $targetDir)
        }
        Get-AzureStorageBlobContent -Container $ContainerName -Blob $dbBackup -Destination $sqlBackupLocation -Context $StorageContext -Force
        Restore-DatabaseBackup -MdfFileLocation $sqlFilesLoc -LdfFileLocation $sqlFilesLoc -BackupLocation $targetDir$dbBackup -RestoredDBName $targetDBName -TargetSqlServer $sqlInstance -TargetSqlUser $targetSqlUser  -TargetSqlPassword (ConvertTo-SecureString $targetSqlPassword -AsPlainText -Force) -TargetSqlAuthenticationIsIntegratedSecurity $false
    }
    catch{
        LogError
        break
    }

    ############ Downloads ISO and installs ERP ###############
    LogWrite ("############ Downloads ISO and installs ERP ###############")
    try{
        Install-Erp -E10Version $erpVersion$erpPatch -installMediaDirectory $targetDir -e10MediaBlobUri $blobUri -blobContainerName $containerName -e10MediaSAS $blobSas
    }
    catch{
        LogError
        break
    }
    <#finally 
    {
        #Remove ERP ISO
        Remove-Item -Path $targetDir"RL"$erpVersion".0.iso" -ErrorAction SilentlyContinue
        if($erpPatch -ne ".0")
        {
            #Remove Update exe
            Remove-Item -Path $targetDir"UD"$erpVersion$erpPatch".exe" -ErrorAction SilentlyContinue
        }
    }#>

    ############ Deploy Appserver + Reports ###############
    LogWrite ("############ Deploy Appserver + Reports ###############")
    try{
        #set the correct SSRS path depending if SQL server version
        if($sqlDataSource.InstanceName -eq "2017")
        {
                $ssrsServerInstallPath = "C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\ReportServer"
        }
        else 
        {
            $ssrsServerInstallPath = C:\Program Files\Microsoft SQL Server\MSRS13.SQL2016\Reporting Services\ReportServer
        }
        Install-ErpAppserver -E10Version $erpVersion$erpPatch -LogFilesPath $logfilesdir -AppserverName $appserverName -EpicorUserName $epicorGSM -EpicorUserPassword (ConvertTo-SecureString -String $epicorPass -AsPlainText -Force) -UseApppoolIdentity $true -ApplicationPoolUserName $apppoolUserName -ApplicationPoolUserPassword (ConvertTo-SecureString -String "Epicor123" -AsPlainText -Force) -EpicorDatabaseName $appserverName -HttpsBinding $erpBinding -DNSIdentity $erpCert -ServerName $env:ComputerName -CreateSsrsDatabase $true -ConfigureSsrsReports $true -SsrsDatabaseName $ssrsDBName -SsrsInstallLocation $ssrsServerInstallPath -SSRSBaseUrl $ssrsBaseURL -TargetSqlServer $sqlInstance -TargetSqlUser $targetSqlUser -TargetSqlPassword (ConvertTo-SecureString -String $targetSqlPassword -AsPlainText -Force) -CheckForBugFixes
    }
    catch{
        LogError
        break
    }

    ################# Install License #####################
    LogWrite ("################# Install License #####################")
    try{
        Get-AzureStorageBlobContent -Container $licContainerName -Blob $licenseID -Destination ($targetDir + $licenseID) -Context $StorageContext -Force
        Install-ErpLicense -LicenseFilePath $targetDir$licenseID -LogFilesPath $logfilesdir -E10Version $erpVersion$erpPatch -AppserverUri ("https://" + $env:ComputerName + "/" + $appserverName) -ErpUserName $epicorGSM -ErpUserPassword (ConvertTo-SecureString -String $epicorPass -AsPlainText -Force) -EndpointBinding $erpBinding -ErpDatabaseName $targetDBName -TargetSqlServer $sqlInstance -TargetSqlUser $targetSqlUser -TargetSqlAuthenticationIsIntegratedSecurity $false -TargetSqlPassword (ConvertTo-SecureString -String $targetSqlPassword -AsPlainText -Force)
    }
    catch{
        LogError
        break
    }

    ############## Launch Conversion Runner ######################
    LogWrite ("############## Launch Conversion Runner ######################")
    try{
        Start-ConversionRunner -E10Version $erpVersion$erpPatch -EpicorSmartClientFolder ($erpInstallPatch + "LocalClients\" + $appserverName) -LogFilesPath $logfilesdir -SysConfigFilePath ($erpInstallPatch + "LocalClients\" + $appserverName + "\Config\" + $appserverName +".sysconfig") -EpicorUserName $epicorGSM -EpicorUserPassword (ConvertTo-SecureString -String $epicorPass -AsPlainText -Force)
    }
    catch{
        LogError
        break
    }

   <# LogWrite ("############## Create Task Agent ######################")
    try{
        Add-TaskAgent -E10Version $erpVersion$erpPatch -LogFilesPath $logfilesdir -TaskAgentName ($appServerName + "Agent") -EpicorAppserverUri "https://$env:ComputerName/$appServerName" -EpicorUserName $epicorGSM -EpicorUserPassword (ConvertTo-SecureString -String $epicorPass -AsPlainText -Force)
    }
    catch{
        LogError
        break
    }#>
}