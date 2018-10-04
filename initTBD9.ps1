New-VHD -ParentPath "C:\Users\Public\TBD.vhdx" -Path "C:\Users\Public\Delta-$args.vhdx" -Differencing
New-VM -Name "$args" -MemoryStartupBytes 8GB -Generation 2 -VHDPath "C:\Users\Public\Delta-$args.vhdx" `
    -BootDevice "VHD" -Switch "IntSwitch" -Path "C:\Virtual Machines\$VMName" -ErrorAction SilentlyContinue
Start-VM "$args"
$ips = Get-VM -VMName $args | Select -ExpandProperty NetworkAdapters | Select IPAddresses 
#$ips = Get-VM | ?{$_.Name -eq $args} | Select -ExpandProperty NetworkAdapters | Select IPAddresses
$ipv4 = $ips.IPAddresses[0]
$trusthosts = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value
Set-Item -Path WSMan:\localhost\Client\TrustedHosts "$trusthosts, $ipv4" -Force
try {
    $password = ConvertTo-SecureString -String "p@ssw0rd1234" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential -ArgumentList "mstest", $password
    $payload = "Invoke-Command -ComputerName $ipv4 -ScriptBlock { Rename-Computer -NewName $args -Restart -Force }"
    $taskPath = "C:\users\Public\$args.renameComputerTask.ps1"
    $taskName = "$args.$ipv4.rename"
      #"Set ComputerName $args from ToBeDetermined for $ipv4"
    Set-Content -Path $taskPath -Value $payload

    $taskAction = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $taskPath -WorkingDirectory c:\users\Public
    $now = [System.DateTime]::Now.AddSeconds(45)
    $taskWhen = New-ScheduledTaskTrigger -Once -At $now

    Register-ScheduledTask -Action $taskAction -Trigger $taskWhen -TaskName $taskName -Description "ScriptingGuy's way." 

    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -RestartCount 3
    Set-ScheduledTask -TaskName $taskName -Settings $settings
}
catch {
    Set-Content -Path c:\users\public\$args.payload.catch.log -Value $_
}
