<##################################################################################################

    Description
    ===========

	- This script does the following - 
		- Installs Windows 2016 roles for ERP 10



    Usage examples
    ==============
    


##################################################################################################>
# Please run this tool to install Server Prerequisites for Server 2016
# Always Run As Administrator
###
$password = ConvertTo-SecureString "Epicor123" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:USERDOMAIN\qatools", $password)
$imports = '#data#'

. ([ScriptBlock]::Create($imports))
Invoke-Command -Credential $credential -ComputerName $env:COMPUTERNAME -ArgumentList $imports -ScriptBlock{
#The below will install all required Roles and Features, this may require a reboot
    Install-WindowsFeature FileAndStorage-Services,File-Services,FS-FileServer,Storage-Services,Web-Server,Web-WebServer,Web-Common-Http,Web-Default-Doc,Web-Dir-Browsing,Web-Http-Errors,Web-Static-Content,Web-Http-Redirect,Web-Health,Web-Http-Logging,Web-Request-Monitor,Web-Http-Tracing,Web-Performance,Web-Stat-Compression,Web-Security,Web-Filtering,Web-Windows-Auth,Web-App-Dev,Web-Net-Ext45,Web-Asp-Net45,Web-ISAPI-Ext,Web-ISAPI-Filter,Web-Includes,Web-Mgmt-Tools,Web-Mgmt-Console,Web-Mgmt-Compat,Web-Metabase,NET-Framework-Features,NET-Framework-Core,NET-Non-HTTP-Activ,NET-Framework-45-Features,NET-Framework-45-Core,NET-Framework-45-ASPNET,NET-WCF-Services45,NET-WCF-HTTP-Activation45,NET-WCF-TCP-Activation45,NET-WCF-TCP-PortSharing45,FS-SMB1,WAS,WAS-Process-Model,WAS-NET-Environment,WAS-Config-APIs,Search-Service,WoW64-Support
    ###
    #this will set Windows Search service to start automatically, required for Epicor Help
    Set-Service -Name "WSearch" -StartupType "Auto"

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