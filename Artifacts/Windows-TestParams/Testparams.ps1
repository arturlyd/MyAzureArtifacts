[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $onetwo = "one",
    [Parameter(Mandatory = $true)]
    [string] $checkbx = $true
 )



###################### Main Block ######################
# Validate-Params
#$UserName = $env:USERNAME
#$secPassword = ConvertTo-SecureString -String "Epicor123" -AsPlainText -Force
#$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$($UserName)", $secPassword)
if ($onetwo -eq "one")
{
    .\one.ps1 $onetwo $checkbx

}
if ($sqlver -eq "two")
{
    .\two.ps1 $onetwo $checkbx
}
#Invoke-Command -ComputerName $env:COMPUTERNAME -Credential $credential -FilePath $command -ArgumentList $PackageList


