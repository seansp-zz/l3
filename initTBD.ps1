New-VHD -ParentPath "C:\Users\Public\TBD.vhdx" -Path "C:\Users\Public\Delta-$args.vhdx" -Differencing
New-VM -Name "$args" -MemoryStartupBytes 8GB -Generation 2 -VHDPath "C:\Users\Public\Delta-$args.vhdx" -BootDevice "VHD" -Switch "IntSwitch" -Path "C:\Virtual Machines\$VMName" -ErrorAction SilentlyContinue
Start-VM "$args"
Sleep 30
$ips = Get-VM -VMName $args | Select -ExpandProperty NetworkAdapters | Select IPAddresses 
#$ips = Get-VM | ?{$_.Name -eq $args} | Select -ExpandProperty NetworkAdapters | Select IPAddresses
$ipv4 = $ips.IPAddresses[0]
$trusthosts = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value
Set-Item -Path WSMan:\localhost\Client\TrustedHosts "$trusthosts, $ipv4" -Force
Invoke-Command -ComputerName $ipv4 -ScriptBlock {HostName}
Invoke-Command -ComputerName $ipv4 -ScriptBlock {param($p1) Rename-Computer -NewName "$p1" -Restart -Force} -ArgumentList "$args"
Sleep 30
#Get-VM | ?{$_.Name -eq “$args”} | Select -ExpandProperty NetworkAdapters | Select IPAddresses
Invoke-Command -ComputerName $ipv4 -ScriptBlock {HostName}
