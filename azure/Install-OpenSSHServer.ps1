Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
Start-LSGNotes -path c:\users\public\Install-OpenSSHServer.log
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}

Write-LSGNote "Adding the Windows Capability for OpenSSH.Server~~~~0.0.1.0"
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
Write-LSGNote "Setting startup Type to Automatic"
Get-Service -Name *ssh* | Set-Service -StartupType Automatic
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}

Write-LSGNote "Starting the service."
Get-Service -Name *ssh* | Start-Service
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}