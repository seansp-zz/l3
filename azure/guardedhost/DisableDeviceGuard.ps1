Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
Start-LSGNotes -path c:\users\public\DisableDeviceGuard.log
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}

Write-LSGNote "building password"
$password = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
Write-LSGNote "building credential"
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $($args[1]), $password

$deviceGuard = {
    Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
    Start-LSGNotes -path c:\users\public\DisableDeviceGuard.localHost.log
    Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\ -Name RequirePlatformSecurityFeatures -Value 0
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }
    Write-LSGNote "Finished. Restarting Machine."
    Restart-Computer -Force
}
Write-LSGNote "Invoking localhost..."
Invoke-Command -ComputerName localhost -Credential $cred -ScriptBlock $deviceGuard 
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
Write-LSGNote "ERROR? How did -this- get Finished."