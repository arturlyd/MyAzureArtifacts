<##################################################################################################

    Description
    ===========

	- This script does the following -
		- Installs Windows 2016 roles for ERP 10

##################################################################################################>

# Always Run As Administrator
$password = ConvertTo-SecureString "Epicor123" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\qatools", $password)
#$username = $env:USERNAME
#$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$($username)", $password)
Invoke-Command -Credential $credential -ComputerName $env:COMPUTERNAME -ScriptBlock{
    #Make sure the installers directory exists so subsequent scripts can access the location without issues.
    $targetDir = "c:\EpicorInstallers\"
    $Logfile = ($targetDir + "ERPW16Roles.log")
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
    LogWrite ("Prueba para ver que dominio y usuario pone " + $env:USERDOMAIN + "\" +$env:USERNAME)
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
    #The below will install all required Roles and Features, this may require a reboot - Commented to use Install-ErpPrerequisities
    #Install-WindowsFeature FileAndStorage-Services,File-Services,FS-FileServer,Storage-Services,Web-Server,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Health,Web-Http-Logging,Web-Request-Monitor,Web-Http-Tracing,Web-Performance,Web-Stat-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext45,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Includes,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,NET-Framework-Features,NET-Framework-Core,NET-Non-HTTP-Activ,NET-Framework-45-Features,NET-Framework-45-Core,NET-Framework-45-ASPNET,NET-WCF-Services45,NET-WCF-HTTP-Activation45,NET-WCF-TCP-Activation45,NET-WCF-TCP-PortSharing45,FS-SMB1,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Search-Service,WoW64-Support
    ####this will set Windows Search service to start automatically, required for Epicor Help
    #Set-Service -Name "WSearch" -StartupType "Auto"
    LogWrite ("############# Installing ERP prerequisites (Install-ErpPrerequisitesForWindowsServer) ###################")
    try{
        Install-ErpPrerequisitesForWindowsServer
    }
    catch
    {
        LogError
        break
    }
    ####### Turn Firewall OFF ###########################
    Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

    ####### Turn IE Enhanced Security Off ######################
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" -Name "1803" -Value "0" #IE Security / Internet / Allow file download
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\3" -Name "1604" -Value "0" #IE Security / Internet / Allow font download
}