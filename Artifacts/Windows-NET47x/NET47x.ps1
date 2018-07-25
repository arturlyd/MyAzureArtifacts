<##################################################################################################

    Description
    ===========

	- This script does the following -
        - Installs .NET 4.7.1 or 4.7.2 depending on the input paramter
        - Default Value: 4.7.2

##################################################################################################>
# Always Run As Administrator
###
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $netver = "4.7.2"
)

$password = ConvertTo-SecureString "Epicor123" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:USERDOMAIN\qatools", $password)

Invoke-Command -Credential $credential -ComputerName $env:COMPUTERNAME -ArgumentList $netver -ScriptBlock{
    Param( $netver )
    . ([ScriptBlock]::Create($netver))
    #Make sure the installers directory exists so subsequent scripts can access the location without issues
    $targetDir = "c:\EpicorInstallers\"
    $Logfile = ($targetDir + "NET47x.log")
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
        write-host $logstring -ForegroundColor Green
        Add-content $Logfile -value ((Get-Date).ToString()+ ": " +$logstring)
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
    if($netver -eq "4.7.1")
    {
        LogWrite ("############# Installing .NET 4.7.1) ###################")
        try{

            choco install dotnet4.7.1
        }
        catch
        {
            LogError
            break
        }
        LogWrite ("############# .NET 4.7.1 successfully installed) ###################")
    }
    else
    {
        LogWrite ("############# Installing .NET 4.7.2) ###################")
        try{

            choco upgrade dotnet4.7.2
        }
        catch
        {
            LogError
            break
        }
        LogWrite ("############# .NET 4.7.2 successfully installed) ###################")
    }
}