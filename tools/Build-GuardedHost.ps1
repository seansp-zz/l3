Param(
    [Parameter(Mandatory=$true)][string] $VMName,
    [Parameter(Mandatory=$true)][string] $adminUsername,
    [Parameter(Mandatory=$true)][string] $adminPassword,
    [System.Int64]$memorySize = 8GB,
    [string] $switchName = "IntSwitch",
    [string] $hgsUser = "shielded\Administrator",
    [string] $hgsPass = $adminPassword,
    [string] $hgsName = "HGS"
)

$global:logPath = $null
#if( !$global:startTime ) { 
$global:startTime = [DateTime]::Now 
#}
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
}
function Wait-UntilVM-Uptime{
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
function Wait-UntilVM-ShutsDown {
  Param(
    [Parameter(Mandatory=$true)][string] $vmName
    )
  Write-Note "Waiting until $vmName shuts down."
  while( (Get-VM -VMName $VMName).Uptime.TotalSeconds -gt 30 )
  {
    Write-Host -NoNewline -ForegroundColor DarkCyan "."
    Sleep 3
  }
  Write-Host -ForegroundColor Cyan "Done."
  Write-Note "$vmName has shut down."
}
function Create-PSCred {
  Param (
    [Parameter(Mandatory=$true)][string] $username,
    [Parameter(Mandatory=$true)][string] $password
  )
  Write-Note "Creating credential for user: $username"
  $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
  New-Object System.Management.Automation.PSCredential -ArgumentList "$username, $password"
}
function Get-IP-From-VmName {
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
function AddTo-TrustedHosts {
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

Start-Notes c:\users\public\guardedhost.deploy.log
$vhd = Build-NewVHDDelta -pathToSource C:\Users\Public\GuardedHostBase.vhdx -vmName $VMName
$vm = Build-NewVM -VMName $vmName -pathToVHD $vhd -memorySize $memorySize -switchName $switchName

Write-Note "Turning on Virtualiztion Extensions for $VMName"
Set-VMProcessor -VMName $VMName -ExposeVirtualizationExtensions $true

Write-Note "Turning on TPM with KeyProtector for $VMName"
$guardian = Get-HgsGuardian -Name "myGuardian"
if( !$guardian )
{
    $guardian = New-HgsGuardian -Name "myGuardian" -GenerateCertificates
}
$keyProtector = New-HgsKeyProtector -Owner $guardian -AllowUntrustedRoot
Set-VMKeyProtector -VMName $VMName -KeyProtector $keyProtector.RawData
Enable-VMTPM -VMName $VMName

Write-Note "Starting $VMName"
Start-VM $VMName

Wait-UntilVM-Uptime $VMName 30
$cred = Create-PSCred $adminUsername $adminPassword 
$ip = Get-IP-From-VmName $VMName
AddTo-TrustedHosts $ip

Write-Note "Renaming the VM to $VMName"
Invoke-Command -ComputerName $ip -ScriptBlock {Rename-Computer -NewName "$args" -Restart -Force} -Credential $cred -ArgumentList $VMName

Wait-UntilVM-ShutsDown $VMName
Wait-UntilVM-Uptime $VMName 30

Write-Note "Turning off DeviceGuard as a PlatformSecurityFeature."
$stepZero = {
  Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\ -Name RequirePlatformSecurityFeatures -Value 0
  Restart-Computer -Force
}
Invoke-Command -ComputerName $ip -Credential $cred -ScriptBlock $stepZero
Wait-UntilVM-ShutsDown $VMName 
Wait-UntilVM-Uptime $VMName 30

Write-Note "Adding HostGuardianServiceRole, Hyper-V, HostGuardian and ManagementTools"
$stepOne = { 
  Install-WindowsFeature -Name HostGuardianServiceRole, Hyper-V, HostGuardian -IncludeManagementTools -Restart
  }
Invoke-Command -ComputerName $ip -Credential $cred -ScriptBlock $stepOne
Wait-UntilVM-ShutsDown $VMName 
Wait-UntilVM-Uptime $VMName 90

$ipv4HGS = Get-IP-From-VmName $hgsName
#Step Two

Write-Host "HGSPass = $hgsPass"
Write-Host "HGSUser = $hgsUser"
Write-Host "HGSName = $hgsName"
Write-Host "HGSipv4 = $ipv4HGS"

Write-Note "Upgrading NuGet, GuardedFabricTools"
$stepTwoa = {
  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
  Install-Module -Name GuardedFabricTools -Repository PSGallery -Force
}
Invoke-Command -ComputerName $ip -Credential $cred -ScriptBlock $stepTwoa

Write-Note "Setting dns to $ipv4HGS for $hgsName"
$stepTwob = {
  netsh interface ipv4 set dnsservers 'Ethernet 2' static $args primary
}
Invoke-Command -ComputerName $ip -Credential $cred -ScriptBlock $stepTwob -ArgumentList $ipv4HGS

Write-Note "Adding to 'shielded.com' domain"
$stepTwoc = {
  $password = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
  $cred = New-Object System.Management.Automation.PSCredential -ArgumentList $($args[1]), $password
  Add-Computer -DomainName "shielded.com" -Credential $cred -Restart
}
Invoke-Command -ComputerName $ip -Credential $cred -ScriptBlock $stepTwoc -ArgumentList $hgsPass, $hgsUser
Wait-UntilVM-ShutsDown $VMName
Wait-UntilVM-Uptime $VMName 90

Write-Note "Configuring attestation Client Configuration on $vmName"
$stepThree = { 
    Set-HgsClientConfiguration -AttestationServerUrl 'http://hgs.shielded.com/Attestation' -KeyProtectionServerUrl 'http://hgs.shielded.com/KeyProtection'
  }
Invoke-Command -ComputerName $ip -Credential $cred -ScriptBlock $stepThree
Write-Note "All Done."