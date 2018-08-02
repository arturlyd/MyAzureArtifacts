[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $sqlver = "sql2016"
 )



###################### Main Block ######################
# Validate-Params
#$UserName = $env:USERNAME
#$secPassword = ConvertTo-SecureString -String "Epicor123" -AsPlainText -Force
#$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$($UserName)", $secPassword)
if ($sqlver -eq "sql2016")
{
    .\ERPSQL2016.ps1

}
if ($sqlver -eq "sql2017")
{
    .\ERPSQL2017.ps1
}
#Invoke-Command -ComputerName $env:COMPUTERNAME -Credential $credential -FilePath $command -ArgumentList $PackageList


