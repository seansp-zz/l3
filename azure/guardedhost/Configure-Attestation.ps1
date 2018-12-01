$password = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $($args[1]), $password

$ghostHgsClientConfiguration = { 
    Set-HgsClientConfiguration -AttestationServerUrl "http://hgs.$args.com/Attestation" -KeyProtectionServerUrl "http://hgs.$args.com/KeyProtection"
}
Invoke-Command -ComputerName localhost -Credential $cred -ScriptBlock $ghostHgsClientConfiguration -ArgumentList $($args[2])


#Invoke-Command -ComputerName $ghostip -Credential $cred -ScriptBlock $ghostJoinDomain -ArgumentList $adminPassword, "$Domain\Administrator", $Domain