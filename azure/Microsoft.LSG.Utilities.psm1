# Microsoft.LSG.Utilities
#

$global:LSG_ReuseLog = $false
$global:LSG_logPath = $null
$global:LSG_startTime = [DateTime]::Now 
function Restart-LSGClock { 
  $global:LSG_startTime = [DateTime]::Now 
}
function Write-LSGNote {
    Param(
        [Parameter(Mandatory=$true)][string] $Message,
        [System.ConsoleColor] $color = [System.ConsoleColor]::DarkYellow
    )
    $now = [System.DateTime]::Now - $global:LSG_startTime
    if( $global:LSG_logPath ) { Add-Content -Path $global:LSG_logPath -Value "[$now] $Message" }
    Write-Host -ForegroundColor DarkCyan -NoNewline [
    Write-Host -NoNewline $now -ForegroundColor DarkGreen
    Write-Host -NoNewline -ForegroundColor DarkCyan "] "
    Write-Host -ForegroundColor $color $Message
}
function Start-LSGNotes {
  Param(
    [Parameter(Mandatory=$true)][string] $path,
    [string] $init = "Starting Logging."
    )
  $now = [System.DateTime]::Now
  $message = "[$now] $init"
  if( [System.IO.File]::Exists( $path ) -and !$global:LSG_ReuseLog )
  {
    Start-LSGNotes "$($path).log" "$init -> found prior $path w/o Global:LSG_ReuseLog set.  Appending .log"
  }
  else {
    Set-Content -Path $path -Value $message -Force
    $global:LSG_logPath = $path
  }
}