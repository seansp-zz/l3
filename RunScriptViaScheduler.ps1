$ScriptToDownload = $args[0]
$DottedFilename = $ScriptToDownload -Replace "\\", "."
$VMToExecute = $args[1]
$Username = $args[2]
$Password = $args[3]

Write-Host "Getting: $DottedFilename for $VMToExecute"

Remove-Item -Path scriptToRun.ps1 -Force -ErrorAction SilentlyContinue
$fileToDownload = "https://raw.githubusercontent.com/seansp/l3/master/$ScriptToDownload"
$exitCode = wget $fileToDownload -outfile "$($VMToExecute).$($DottedFilename)"

$nextArgs = ""
$idx = 4
while( $idx -lt $args.Count )
{
  $nextArgs += $args[$idx]
  $idx += 1

  if( $idx -lt $args.Count ) { $nextArgs += " " }
}

Write-Host "NEXTARGS = '$nextArgs'"

$taskFile = @()
$taskFile += "# First get the IP address for $VMToExecute now that it should be booted up."
$taskFile += "`$ips = Get-VM -VMName $VMToExecute | Select -ExpandProperty NetworkAdapters | Select IPAddresses"
$taskFile += "`$ipv4 = `$ips.IPAddresses[0]"
$taskFile += "Set-Content -Path c:\users\public\$VMToExecute.$DottedFilename.log -Value `"Started $DottedFilename for `$ipv4`""
$taskFile += "try {"
$taskFile += "  Enable-PSRemoting -Force"
$taskFile += "  `$password = ConvertTo-SecureString -String `"$Password`" -AsPlainText -Force"
$taskFile += "  `$cred = New-Object System.Management.Automation.PSCredential -ArgumentList `"$Username`", `$password"
if( $idx -gt 4 )
{
$taskFile += "  Invoke-Command -ComputerName `$ipv4 -FilePath c:\users\public\$VMToExecute.$DottedFilename -Credential `$cred -ArgumentList $nextArgs"
} else
{
$taskFile += "  Invoke-Command -ComputerName `$ipv4 -FilePath c:\users\public\$VMToExecute.$DottedFilename -Credential `$cred"
}
$taskFile += "  Add-Content -Path c:\users\public\$VMToExecute.$DottedFilename.log -Value `"Completed $DottedFilename for `$ipv4`""
$taskFile += "} catch {"
$taskFile += "  Add-Content -Path c:\users\public\$VMToExecute.$DottedFilename.log -Value `$_"
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

    Write-Host "Start Date: $date"
    $taskPath = "C:\users\Public\$VMToExecute.$DottedFilename.Task.ps1"
    Set-Content -Path $taskPath -Value $taskFile
    Write-Host "Start Time: $time"
    & schtasks.exe /CREATE /F /RL HIGHEST /RU $Username /RP $Password /SC ONCE /S LocalHost /TR "powershell.exe -ExecutionPolicy ByPass -File $taskPath" /TN "$VMToExecute.$DottedFilename" /SD $date /ST $time
}
catch {
    Set-Content -Path c:\users\public\$args.rename.catch.log -Value $_
}


