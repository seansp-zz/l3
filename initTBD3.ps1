New-VHD -ParentPath "C:\Users\Public\TBD.vhdx" -Path "C:\Users\Public\Delta-$args.vhdx" -Differencing
New-VM -Name "$args" -MemoryStartupBytes 8GB -Generation 2 -VHDPath "C:\Users\Public\Delta-$args.vhdx" -BootDevice "VHD" -Switch "IntSwitch" -Path "C:\Virtual Machines\$VMName" -ErrorAction SilentlyContinue
Start-VM "$args"
Sleep 30
$ips = Get-VM -VMName $args | Select -ExpandProperty NetworkAdapters | Select IPAddresses 
#$ips = Get-VM | ?{$_.Name -eq $args} | Select -ExpandProperty NetworkAdapters | Select IPAddresses
$ipv4 = $ips.IPAddresses[0]
$trusthosts = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value
Set-Item -Path WSMan:\localhost\Client\TrustedHosts "$trusthosts, $ipv4" -Force

$password = ConvertTo-SecureString -String "p@ssw0rd1234" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList "mstest", $password
$payload = "Invoke-Command -ComputerName $ipv4 -ScriptBlock { Rename-Computer -NewName $args -Restart -Force }"
Set-Content -Path c:\users\public\payload.ps1 -Value $payload
Start-Process powershell.exe -ArgumentList c:\users\public\payload.ps1 -NoNewWindow -Credential $cred