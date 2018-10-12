Param(
    [Parameter(Mandatory=$true)][string] $VMName,
    [Parameter(Mandatory=$true)][string] $adminUsername,
    [Parameter(Mandatory=$true)][string] $adminPassword,
    [System.Int64] $memorySize = 4GB )
  
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
  
  $taskPath = "C:\users\Public\Build-HGS.ps1"
  & schtasks.exe /CREATE /F /RL HIGHEST /RU $adminUsername /RP $adminPassword /SC ONCE /S LocalHost /TR "powershell.exe -ExecutionPolicy ByPass -File $taskPath -VMName $VMName -adminUsername $adminUsername -adminPassword $adminPassword -memorySize $memorySize" /TN "Build Host Guardian Service AD <$VMName>" /SD $date /ST $time