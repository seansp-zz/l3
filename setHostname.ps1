$ips = Get-VM -VMName $args | Select -ExpandProperty NetworkAdapters | Select IPAddresses 
#$ips = Get-VM | ?{$_.Name -eq $args} | Select -ExpandProperty NetworkAdapters | Select IPAddresses
$ipv4 = $ips.IPAddresses[0]
$trusthosts = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value
Set-Item -Path WSMan:\localhost\Client\TrustedHosts "$trusthosts, $ipv4" -Force
Invoke-Command -ComputerName $ipv4 -ScriptBlock {HostName}
Invoke-Command -ComputerName $ipv4 -ScriptBlock {param($p1) Rename-Computer -NewName "$p1" -Restart -Force} -ArgumentList "$args"
