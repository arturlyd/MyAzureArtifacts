[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $sqlver = "sql2016",
    [Parameter(Mandatory = $false)]
    [string] $ssms = $true
)



###################### Main Block ######################
# Validate-Params
#$UserName = $env:USERNAME
#$secPassword = ConvertTo-SecureString -String "Epicor123" -AsPlainText -Force
#$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$($UserName)", $secPassword)
if ($sqlver -eq "sql2016")
{
    .\ERPDLSQL2016.ps1 $ssms

}
if ($sqlver -eq "sql2017")
{
    write-host ("SSMS before script >>> "+ $ssms.ToString())
    .\ERPDLSQL2017.ps1 $ssms
}
#Invoke-Command -ComputerName $env:COMPUTERNAME -Credential $credential -FilePath $command -ArgumentList $PackageList


