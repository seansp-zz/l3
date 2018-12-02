Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
Start-LSGNotes -path c:\users\public\JoinDomain.log
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}

Write-LSGNote "building password"
$password = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
Write-LSGNote "building credential"
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $($args[1]), $password

Write-LSGNote "Adding the computer to $($args[2]).com"
Add-Computer -DomainName "$($args[2]).com" -Credential $cred -Restart
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
#Invoke-Command -ComputerName $ghostip -Credential $cred -ScriptBlock $ghostJoinDomain -ArgumentList $adminPassword, "$Domain\Administrator", $Domain