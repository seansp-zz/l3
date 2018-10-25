Param(
    [Parameter(mandatory=$false)] [string] $HGSName = "NestedHGS",
    [Parameter(mandatory=$false)] [Int64]  $hgsMem = 4GB,
    [Parameter(mandatory=$false)] [Int64]  $switchName = "IntSwitch",
    [Parameter(mandatory=$false)] [string] $Domain = "shielded",
    [Parameter(mandatory=$true)]  [string] $adminPassword,
    [Parameter(mandatory=$false)] [string] $GhostName = "GuardedHost",
    [Parameter(mandatory=$false)] [Int64]  $GhostMem = 8GB
)
  
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
  
  $taskPath = "C:\users\Public\Build-NestedLSVM.ps1"
  $taskArgs = "-HGSName $HgsName -hgsMem $hgsMemory -switchName $switchName -Domain $Domain -adminPassword $AdminPassword -GhostName $GhostName -GhostMem $GhostMem"
  & schtasks.exe /CREATE /F /RL HIGHEST /RU $adminUsername /RP $adminPassword /SC ONCE /S LocalHost /TR "powershell.exe -ExecutionPolicy ByPass -File $taskPath $taskArgs" /TN "Build Nested LSVM $Domain" /SD $date /ST $time