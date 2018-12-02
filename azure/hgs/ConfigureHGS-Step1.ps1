Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
Start-LSGNotes -path c:\users\public\ConfigureHGS-Step1.log
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}

Write-LSGNote "Installing HostGuardianServiceRole ...."
Install-WindowsFeature HostGuardianServiceRole -IncludeManagementTools
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
Write-LSGNote "Install-HgsServer -- $($args[1]).com"
$securePass = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
Install-HgsServer -HgsDomainName "$($args[1]).com" -SafeModeAdministratorPassword $securePass -Restart
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
