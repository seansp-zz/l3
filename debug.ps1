$me = whoami
Set-Content -Path c:\users\public\debug.$args.whoami.log -Value $me
$ips = Get-VM -VMName $args | Select -ExpandProperty NetworkAdapters | Select IPAddresses 
#$ips = Get-VM | ?{$_.Name -eq $args} | Select -ExpandProperty NetworkAdapters | Select IPAddresses
$ipv4 = $ips.IPAddresses[0]
Write-Host "IPv4 Address for $args = $ipv4"
Set-Content -Path c:\users\public\debug.$args.log -Value $ipv4
$trusthosts = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value
Set-Item -Path WSMan:\localhost\Client\TrustedHosts "$trusthosts, $ipv4" -Force
$password = ConvertTo-SecureString -String "p@ssw0rd1234" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList "mstest", $password
$sb_hostname = {hostname}
$s = New-PSSession -ComputerName $ipv4 -Credential $cred
$originalHostName = Invoke-Command -Session $s -ScriptBlock $sb_hostname
Set-Content -Path C:\users\public\debug.$args.originalHostname.log -Value $originalHostName
Write-Host "Retrieved Hostname = $originalHostName"
$sb_setHostname = {param($newName) Rename-Computer -NewName $newName -Restart -Force}
Invoke-Command -Session $s -ScriptBlock $sb_setHostname -ArgumentList "debug-changeme"



