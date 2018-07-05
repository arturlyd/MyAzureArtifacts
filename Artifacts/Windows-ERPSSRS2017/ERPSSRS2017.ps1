<##################################################################################################

    Description
    ===========

	- This script does the following - 
		-Configures SSRS 2017



    Usage examples
    ==============
    


##################################################################################################>
$SQLServerInstance = "(local)\SQL20017"
$Logfile = ("C:\EpicorInstallers\SSRSConfig.log")
############# GET Latest 200 update ##############
Function LogWrite ([string]$logstring)
{
    
    Add-content $Logfile -value ((Get-Date).ToString()+ ": " +$logstring)
}
Remove-Item $Logfile -ErrorAction SilentlyContinue
##################################################

##################  SSRS Configuration ##################
try
{
    LogWrite ("Before RSConfig");
    rsconfig -c -s $SQLServerInstance -d ReportServer -a SQL -u sa -p Epicor123 -i SSRS

    LogWrite ("Before GetConfigset");
    function Get-ConfigSet()
    {
	    return Get-WmiObject -Namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v14\Admin" `
		    -class MSReportServer_ConfigurationSetting -ComputerName localhost
    }

    LogWrite ("Before Set Execution policy");
    # Allow importing of sqlps module
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

    # Retrieve the current configuration
    $configset = Get-ConfigSet

    $configset
    LogWrite ("Before IF configset");
    If (! $configset.IsInitialized)
    {
        LogWrite ("Before Generate database creation script");
	    # Get the ReportServer and ReportServerTempDB creation script
	    [string]$dbscript = $configset.GenerateDatabaseCreationScript("ReportServer", 1033, $false).Script
        LogWrite ("Before established connection");
	    # Establish a connection to the 
	    $conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection 
        $conn.ServerInstance = $SQLServerInstance
        $conn.LoginSecure = $FALSE
        $conn.Login = "sa"
        $conn.Password = "Epicor123"
        #Connect to the local, default instance of SQL Server
        $smo = new-object Microsoft.SqlServer.Management.Smo.Server($conn)
        LogWrite ("Before Create databases");
	    # Create the ReportServer and ReportServerTempDB databases
	    $db = $smo.Databases["master"]
	    $db.ExecuteNonQuery($dbscript)
        LogWrite ("Before setting permissions to db");
	    # Set permissions for the databases
	    $dbscript = $configset.GenerateDatabaseRightsScript($configset.WindowsServiceIdentityConfigured, "ReportServer", $false, $true).Script
        #$dbscript = $configset.GenerateDatabaseRightsScript("localhost\qatools", "ReportServer", $false, $false).Script
	    $db.ExecuteNonQuery($dbscript)

        LogWrite ("Before sedtting db connection info");
	    # Set the database connection info
	    $configset.SetDatabaseConnection($SQLServerInstance, "ReportServer", 2, "", "")
        LogWrite ("Before setting virtual directory");
	    $configset.SetVirtualDirectory("ReportServerWebService", "ReportServer", 1033)
	    $configset.ReserveURL("ReportServerWebService", "http://+:80", 1033)

	    # Did the name change?
	    $configset.SetVirtualDirectory("ReportServerWebApp", "Reports", 1033)
	    $configset.ReserveURL("ReportServerWebApp", "http://+:80", 1033)

	    $configset.InitializeReportServer($configset.InstallationID)


	    # Import the SQL Server PowerShell module
	    Import-Module sqlps -DisableNameChecking | Out-Null

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
}

Catch
{
    LogWrite ("Error found: " + $_.Exception.Message + " ") 
}
