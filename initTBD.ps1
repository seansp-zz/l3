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
$taskFile += "if( `$trusthosts.Length -gt 0 ) { `$trusthosts = `"`$trusthosts, `$ipv4, $args`" }"
$taskFile += "else { `$trusthosts = `"`$ipv4, $args`" }"
$taskFile += "Set-Item -Path WSMan:\localhost\Client\TrustedHosts `"`$trusthosts, `$ipv4, $args`" -Force"
$taskFile += "Set-Content -Path c:\users\public\$args.renameStarted.log -Value `"Started rename for `$ipv4`""
$taskFile += "try {"
$taskFile += "  Enable-PSRemoting -Force"
$taskFile += "  `$password = ConvertTo-SecureString -String `"p@ssw0rd1234`" -AsPlainText -Force"
$taskFile += "  `$cred = New-Object System.Management.Automation.PSCredential -ArgumentList `"mstest`", `$password"
$taskFile += "  Invoke-Command -ComputerName `$ipv4 -ScriptBlock {Rename-Computer -NewName $args -Restart -Force} -Credential `$cred"
$taskFile += "  Set-Content -Path c:\users\public\$args.renameCompleted.log -Value `"Completed rename for `$ipv4`""
$taskFile += "} catch {"
$taskFile += "  Set-Content -Path c:\users\public\$args.renameError.log -Value `$_"
$taskFile += "}"

try {
    $now = [System.DateTime]::Now
    $date = ""
    if( $now.Month -lt 10 ) { $date = "0" }
    $date = "$date$($now.Month)"
    if( $now.Day -lt 10 ) { $date = "$date/0$($now.Day)" }
    else { $date = "$date/$($now.Day)" }
    $date = "$date/$($now.Year)"
    $now = $now.AddMinutes(1)
    $time = "$($now.Hour):"
    if( $now.Hour -lt 10 ) { $time = "0$time" }
    if( $now.Minute -lt 10) { $time = "$($time)0$($now.Minute)" }
    else { $time = "$time$($now.Minute)" }
    
    $taskPath = "C:\users\Public\$args.renameComputerTask.ps1"
    Set-Content -Path $taskPath -Value $taskFile
    & schtasks.exe /CREATE /F /RL HIGHEST /RU mstest /RP p@ssw0rd1234 /SC ONCE /S LocalHost /TR "powershell.exe -ExecutionPolicy ByPass -File $taskPath" /TN "$args Rename" /SD $date /ST $time
}
catch {
    Set-Content -Path c:\users\public\$args.rename.catch.log -Value $_
}
