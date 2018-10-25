Param(
    [Parameter(mandatory=$false)] [string] $HGSName = "NestedHGS",
    [Parameter(mandatory=$false)] [string]  $hgsMem = 4GB,
    [Parameter(mandatory=$false)] [string]  $switchName = "IntSwitch",
    [Parameter(mandatory=$false)] [string] $Domain = "shielded",
    [Parameter(mandatory=$true)]  [string] $adminPassword,
    [Parameter(mandatory=$false)] [string] $GhostName = "GuardedHost",
    [Parameter(mandatory=$false)] [string]  $GhostMem = 8GB,
    [Parameter(mandatory=$false)]  [string] $adminUsername = "mstest"

)

  #The GB and MB powershell type identifiers are not recognized by the .Net types.
  #Dividing the string by a typed 1 will result in a proper type.
  $hgsMemVal = $hgsMem / [uint64] 1
  $GhostMemVal = $GhostMem / [uint64] 1
  
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
  $taskArgs = "-HGSName $HgsName -hgsMem $hgsMemVal -switchName $switchName -Domain $Domain -adminPassword $AdminPassword -GhostName $GhostName -GhostMem $GhostMemVal"
  & schtasks.exe /CREATE /F /RL HIGHEST /RU $adminUsername /RP $adminPassword /SC ONCE /S LocalHost /TR "powershell.exe -ExecutionPolicy ByPass -File $taskPath $taskArgs" /TN "Build Nested LSVM $Domain" /SD $date /ST $time