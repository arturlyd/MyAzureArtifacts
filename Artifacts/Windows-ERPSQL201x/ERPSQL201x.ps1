[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $sqlver = "sql2016",
    [Parameter(Mandatory = $false)]
    [string] $ssms = $true
)



###################### Main Block ######################
# Validate-Params
$UserName = $env:USERNAME
$secPassword = ConvertTo-SecureString -String "Epicor123" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$($UserName)", $secPassword)
write-host "folder del script: " $PSScriptRoot
if ($sqlver -eq "sql2016")
{
    $command = "$PSScriptRoot\ERPDLSQL2016.ps1 $ssms"

}
if ($sqlver -eq "sql2017")
{
    $command = "$PSScriptRoot\ERPDLSQL2017.ps1 $ssms"
}
Invoke-Command -ComputerName $env:COMPUTERNAME -Credential $credential -FilePath $command -ArgumentList $PackageList


