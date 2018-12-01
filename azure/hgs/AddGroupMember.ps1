$password = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $($args[1]), $password
Add-ADGroupMember "Guarded Hosts" -Members GuardedHost$ -Credential $cred
#Invoke-Command -ComputerName $ghostip -Credential $cred -ScriptBlock $ghostJoinDomain -ArgumentList $adminPassword, "$Domain\Administrator", $Domain