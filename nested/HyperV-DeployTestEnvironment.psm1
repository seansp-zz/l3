function Restart-Clock { 
  $global:startTime = [DateTime]::Now 
}
function Write-Note {
    Param(
        [Parameter(Mandatory=$true)][string] $Message,
        [System.ConsoleColor] $color = [System.ConsoleColor]::DarkYellow
    )
    $now = [System.DateTime]::Now - $global:startTime
    if( $global:logPath ) { Add-Content -Path $global:logPath -Value "[$now] $Message" }
    Write-Host -ForegroundColor DarkCyan -NoNewline [
    Write-Host -NoNewline $now -ForegroundColor DarkGreen
    Write-Host -NoNewline -ForegroundColor DarkCyan "] "
    Write-Host -ForegroundColor $color $Message
}
function Start-Notes {
  Param(
    [Parameter(Mandatory=$true)][string] $path,
    [string] $init = "Starting Logging."
    )
  $now = [System.DateTime]::Now
  $message = "[$now] $init"
  Set-Content -Path $path -Value $message -Force
  $global:logPath = $path
  Restart-Clock
}
function Wait-UntilVMUptime{
  Param(
    [Parameter(Mandatory=$true)][string] $vmName,
    [Parameter(Mandatory=$true)][int] $secondsUptime
    )
  Write-Note "Waiting until $vmName has been running for $secondsUptime seconds."
  while( (Get-VM -VMName $VMName).Uptime.TotalSeconds -lt $secondsUptime )
  {
    Write-Host -NoNewline -ForegroundColor DarkCyan "."
    Sleep 3
  }
  Write-Host -ForegroundColor Cyan "Done."
  Write-Note "$vmName has been up for longer than $secondsUptime seconds."
}
function Wait-UntilVMShutsDown {
  Param(
    [Parameter(Mandatory=$true)][string] $vmName
    )
  Write-Note "Waiting until $vmName shuts down."
  while( (Get-VM -VMName $VMName).Uptime.TotalSeconds -gt 30 )
  {
    Write-Host -NoNewline -ForegroundColor DarkCyan "."
    Sleep 3
    if( (Get-VM -VMName $VMName).Uptime.TotalSeconds -gt 300 )
    {
      Write-Note "Waited for 300 seconds.  TIMEOUT."
      break
    }
  }
  Write-Host -ForegroundColor Cyan "Done."
  Write-Note "$vmName has shut down."
}
function Get-NewPSCred {
  Param (
    [Parameter(Mandatory=$true)][string] $username,
    [Parameter(Mandatory=$true)][string] $password
  )
  Write-Note "Creating credential for user: $username"
  $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
  New-Object System.Management.Automation.PSCredential -ArgumentList "$username, $password"
}
function Get-IPFromVmName {
  Param(
    [Parameter(Mandatory=$true)][string] $vmName
    )
  Write-Note "Retrieving IP for $VMName from Hyper-V"
  $vm = Get-VM $vmName
  if( $vm ) 
  {
    $ips = $vm | Select -ExpandProperty NetworkAdapters | Select IPAddresses
    if( $ips )
    {
      $ips.IPAddresses[0]
    }
  }
}
function Add-ToTrustedHosts {
  Param(
    [Parameter(Mandatory=$true)][string] $hostname
  )
  $trustedHosts = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value
  $doNotAdd = $false
  if( $trustedHosts.Length -gt 0 )
  {
    if( $trustedHosts.Contains($hostname) )
    {
      Write-Note "No action necessary. $hostname is already present in Trusted Hosts."
      $doNotAdd = $true
    } else
    {
      $trustedHosts = "$trustedHosts, $hostname"
    }
  } else { $trustedHosts = $hostname }
  if( $doNotAdd -eq $false )
  {
    Write-Note "Adding $hostname to Trusted Hosts."
    Set-Item -Path WSMan:\localhost\Client\TrustedHosts "$trustedhosts" -Force
  }
}
function Build-NewVHDDelta {
  Param(
    [Parameter(Mandatory=$true)][string] $pathToSource,
    [Parameter(Mandatory=$true)][string] $vmName
    )
    $newPath = $pathToSource.Replace(".vhdx", ".$vmName.vhdx")
    if( New-VHD -ParentPath $pathToSource -Path $newPath -Differencing )
    {
      Write-Note "Built new difference drive $newPath"
      $newPath
    }
}
function Build-NewVM {
  Param(
    [Parameter(Mandatory=$true)][string] $vmName,
    [Parameter(Mandatory=$true)][string] $pathToVHD,
    [Parameter(Mandatory=$true)][System.Int64] $memorySize,
    [string] $switchName = "IntSwitch"
    )
  Write-Note "Building $VMName with $memorySize Memory" 
  New-VM -Name $vmName -MemoryStartupBytes $memorySize -Generation 2 -VHDPath $pathToVHD -BootDevice VHD -SwitchName $switchName -Path "C:\Virtual Machines\$VMName"
}