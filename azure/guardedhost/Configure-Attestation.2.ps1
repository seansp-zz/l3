Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
Start-LSGNotes -path c:\users\public\Configure-Attestation.log

Write-LSGNote "building password"
$password = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
Write-LSGNote "building credential"
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $($args[1]), $password

$ghostHgsClientConfiguration = {
    Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
    Start-LSGNotes -path c:\users\public\Configure-Attestation.1.ghost.log
    Write-LSGNote "Using AttestationServerUrl - http://hgs.$args.com/Attestation"
    Write-LSGNote "Using KeyProtectuinServerUrl - http://hgs.$args.com/KeyProtection"
    Set-HgsClientConfiguration -AttestationServerUrl "http://hgs.$args.com/Attestation" -KeyProtectionServerUrl "http://hgs.$args.com/KeyProtection"
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }
    Write-LSGNote "Finished."
}
Write-LSGNote "Invoking localhost..."
Invoke-Command -ComputerName localhost -Credential $cred -ScriptBlock $ghostHgsClientConfiguration -ArgumentList $($args[2])
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
Write-LSGNote "Finished."
#Invoke-Command -ComputerName $ghostip -Credential $cred -ScriptBlock $ghostJoinDomain -ArgumentList $adminPassword, "$Domain\Administrator", $Domain