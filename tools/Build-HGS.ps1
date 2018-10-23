Param(
    [Parameter(Mandatory=$true)][string] $VMName,
    [Parameter(Mandatory=$true)][string] $adminUsername,
    [Parameter(Mandatory=$true)][string] $adminPassword,
    [System.Int64]$memorySize = 4GB,
    [string] $switchName = "IntSwitch"
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

Start-Notes c:\users\public\hgs.deploy.log
$vhd = Build-NewVHDDelta -pathToSource C:\Users\Public\HGS.vhdx -vmName $VMName
$vm = Build-NewVM -VMName $vmName -pathToVHD $vhd -memorySize $memorySize -switchName $switchName


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

Write-Note "Adding HostGuardianServiceRole and Management Tools"
$stepOne = { 
  Install-WindowsFeature HostGuardianServiceRole -IncludeManagementTools -Restart
  }
Invoke-Command -ComputerName $ip -Credential $cred -ScriptBlock $stepOne

Wait-UntilVM-ShutsDown $VMName
Wait-UntilVM-Uptime $VMName 30

Write-Note "Installing HgsServer for 'shielded.com'"
$stepTwo = {
  $securePass = ConvertTo-SecureString -String "$args" -AsPlainText -Force
  Install-HgsServer -HgsDomainName "shielded.com" -SafeModeAdministratorPassword $securePass -Restart
}
Invoke-Command -ComputerName $ip -Credential $cred -ScriptBlock $stepTwo -ArgumentList $adminPassword

Wait-UntilVM-ShutsDown $VMName
Wait-UntilVM-Uptime $VMName 90

$shieldedCred = Create-PSCred "shielded\Administrator" $adminPassword
Write-Note "Using new credential : $($shieldedCred.UserName)"


Write-Note "Turning off IOMMU attestation requirement."
$stepZero = {
  Disable-HgsAttestationPolicy Hgs_IommuEnabled
}
Invoke-Command -ComputerName $ip -Credential $shieldedCred -ScriptBlock $stepZero

Write-Note "Creating certificates and Initialiing the HgsServer"
#STEP 3
$stepThree = {
  $securePass = ConvertTo-SecureString -String "$args" -AsPlainText -Force
  $hgs_signer_cert = New-SelfSignedCertificate -FriendlyName "HGS Signer" -DnsName "shielded.com"
  $hgs_encrypt_cert = New-SelfSignedCertificate -FriendlyName "HGS Encrypt" -DnsName "shielded.com"

  New-Item -Path "C:\PFX" -ItemType Directory
  Export-PfxCertificate -FilePath "C:\PFX\HGS_Signer.pfx" -Cert $hgs_signer_cert -Password $securePass -Force
  Export-PfxCertificate -FilePath "C:\PFX\HGS_Encrypt.pfx" -Cert $hgs_encrypt_cert -Password $securePass -Force

  Initialize-HgsServer -LogDirectory "C:\PFX" -HgsServiceName HGS -Http -TrustActiveDirectory -SigningCertificatePath C:\PFX\HGS_Signer.pfx -SigningCertificatePassword $securePass -EncryptionCertificatePath "C:\PFX\HGS_Encrypt.pfx" -EncryptionCertificatePassword $securePass
}
Invoke-Command -ComputerName $ip -Credential $shieldedCred -ScriptBlock $stepThree -ArgumentList $adminPassword
Invoke-Command -ComputerName $ip -Credential $shieldedCred -ScriptBlock $stepThree -ArgumentList $adminPassword

Write-Note "Adding the Guarded Host group to $VMName."
$stepFour = {
  $name = 'Guarded Hosts'
  New-ADGroup -Name $name -GroupScope Global -GroupCategory Security
  $group = Get-ADGroup $name
  Add-HgsAttestationHostGroup -Name $group.Name -Identifier $group.SID 
}
Invoke-Command -ComputerName $ip -Credential $shieldedCred -ScriptBlock $stepFour
Write-Note "Configured. Now running diagnostics."
Invoke-Command -ComputerName $ip -Credential $shieldedCred -ScriptBlock { Get-HgsTrace -RunDiagnostics -Detailed }

#Now build the Guarded Host.

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

  $eightGB = 8GB
  $taskPath = "C:\users\Public\Build-GuardedHost.ps1"
  & schtasks.exe /CREATE /F /RL HIGHEST /RU $adminUsername /RP $adminPassword /SC ONCE /S LocalHost /TR "powershell.exe -ExecutionPolicy ByPass -File $taskPath -VMName GuardedHost -adminUsername $adminUsername -adminPassword $adminPassword -memorySize $eightGB -hgsName $VMName" /TN "Build GuardedHost for $VMName" /SD $date /ST $time