New-VHD -ParentPath "C:\Users\Public\TBD.vhdx" -Path "C:\Users\Public\Delta-$args.vhdx" -Differencing
New-VM -Name "$args" -MemoryStartupBytes 8GB -Generation 2 -VHDPath "C:\Users\Public\Delta-$args.vhdx" `
    -BootDevice "VHD" -Switch "IntSwitch" -Path "C:\Virtual Machines\$VMName" -ErrorAction SilentlyContinue
Start-VM "$args"

$taskFile = @()
$taskFile += "# First get the IP address for $args now that it should be booted up."
$taskFile += "`$ips = Get-VM -VMName $args | Select -ExpandProperty NetworkAdapters | Select IPAddresses"
$taskFile += "`$ipv4 = `$ips.IPAddresses[0]"
$taskFile += "# Now add the IP address to the trusted hosts file."
$taskFile += "`$trusthosts = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value"
$taskFile += "Set-Item -Path WSMan:\localhost\Client\TrustedHosts `"`$trusthosts, `$ipv4`" -Force"
$taskFile += "Set-Content -Path c:\users\public\$args.renameStarted.log -Value `"Started rename for `$ipv4`""
$taskFile += "try {"
$taskFile += "  `$password = ConvertTo-SecureString -String `"p@ssw0rd1234`" -AsPlainText -Force"
$taskFile += "  `$cred = New-Object System.Management.Automation.PSCredential -ArgumentList `"mstest`", `$password"
$taskFile += "  Invoke-Command -ComputerName `$ipv4 -ScriptBlock {Rename-Computer -NewName $args -Restart -Force} -Credential `$cred"
$taskFile += "  Set-Content -Path c:\users\public\$args.renameCompleted.log -Value `"Completed rename for `$ipv4`""
$taskFile += "} catch {"
$taskFile += "  Set-Content -Path c:\users\public\$args.renameError.log -Value `$_"
$taskFile += "}"

try {
    $taskPath = "C:\users\Public\$args.renameComputerTask.ps1"
    Set-Content -Path $taskPath -Value $taskFile
    $taskName = "$args rename"
    $taskAction = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $taskPath -WorkingDirectory c:\users\Public
    $now = [System.DateTime]::Now.AddSeconds(45)
    $taskWhen = New-ScheduledTaskTrigger -Once -At $now

    Register-ScheduledTask -Action $taskAction -Trigger $taskWhen -TaskName $taskName -Description "Rename Computer"
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 5) -RestartCount 3
    Set-ScheduledTask -TaskName $taskName -Settings $settings -User "mstest" -Password "p@ssw0rd1234"
    Set-Content -Path c:\users\public\$args.renameTaskCreation.Created.log -Value "Task $taskName created and scheduled."
}
catch {
    Set-Content -Path c:\users\public\$args.renameTaskCreation.catch.log -Value $_
}
