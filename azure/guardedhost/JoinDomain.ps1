$password = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $($args[1]), $password
Add-Computer -DomainName "$($args[2]).com" -Credential $cred -Restart
#Invoke-Command -ComputerName $ghostip -Credential $cred -ScriptBlock $ghostJoinDomain -ArgumentList $adminPassword, "$Domain\Administrator", $Domain