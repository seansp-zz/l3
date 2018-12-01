Param(
    [Parameter(Mandatory=$true)][string] $domainName,
    [Parameter(Mandatory=$true)][string] $adminPassword
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

  $taskPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.9.2\Downloads\1\ConfigureHGS-Step2.ps1"
  & schtasks.exe /CREATE /F /RL HIGHEST /RU $domainName\mstest /RP $adminPassword /SC ONCE /S LocalHost /TR "powershell.exe -ExecutionPolicy ByPass -File $taskPath $adminPassword $domainName" /TN "InitializeHGS" /SD $date /ST $time