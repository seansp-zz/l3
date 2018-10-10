Param(
    [Parameter(Mandatory=$true)][string] $VMName,
    [Parameter(Mandatory=$true)][string] $adminUsername,
    [Parameter(Mandatory=$true)][string] $adminPassword,
    [System.Int64]$memorySize = 4GB,
    [string] $switchName = "IntSwitch",
    $guardedHostName = "GuardedHost"
)
$logPath = "c:\users\public\configHGS.log"
$errorPath = "c:\users\public\configHGS.error.log"

$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] Creating the VHD, VM and starting $VMName"
Set-Content -Path $logPath -Value $report
Write-Host $report

New-VHD -ParentPath C:\Users\Public\TBD.vhdx -Path C:\Users\Public\Delta-$VMName.vhdx -Differencing
New-VM -Name $VMName -MemoryStartupBytes $memorySize -Generation 2 -VHDPath C:\Users\Public\Delta-$VMName.vhdx `
    -BootDevice VHD -Switch $switchName -Path "C:\Virtual Machines\$VMName"
Start-VM $VMName

$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] Waiting until VM is up for 30 seconds and then rename."
Add-Content -Path $logPath -Value $report
Write-Host $report
Sleep 5
while( (Get-VM -VMName $VMName).Uptime.TotalSeconds -lt 30 )
{
  Write-Host "peaking towards 30..."
  Sleep 3
}

## Rename

$password = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList "$adminUsername, $password"

##############

# First get the IP address for HGS now that it should be booted up.
$ips = Get-VM -VMName $VMName | Select -ExpandProperty NetworkAdapters | Select IPAddresses
$ipv4 = $ips.IPAddresses[0]
# Now add the IP address to the trusted hosts file.
$trusthosts = (Get-Item -Path WSMan:\localhost\Client\TrustedHosts).Value
if( $trusthosts.Length -gt 0 ) { $trusthosts = "$trusthosts, $ipv4, $VMName" }
else { $trusthosts = "$ipv4, $VMName" }
Set-Item -Path WSMan:\localhost\Client\TrustedHosts "$trusthosts" -Force

Invoke-Command -ComputerName $ipv4 -ScriptBlock {Rename-Computer -NewName "$args" -Restart -Force} -Credential $cred -ArgumentList $VMName

##############
while( (Get-VM -VMName $VMName).Uptime.TotalSeconds -gt 30 )
{
  Write-Host "WAITING FOR REBOOT"
  Sleep 3
}
Sleep 5
while( (Get-VM -VMName $VMName).Uptime.TotalSeconds -lt 30 )
{
  Write-Host "peaking towards 30..."
  Sleep 3
}








$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] Adding the HostGuardianServiceRole"
Add-Content -Path $logPath -Value $report
Write-Host $report

#Step One: Connect to the HGS-To-Be and install the first component.
$stepOne = { 
  Install-WindowsFeature HostGuardianServiceRole -IncludeManagementTools -Restart
  }
Invoke-Command -ComputerName $ipv4 -Credential $cred -ScriptBlock $stepOne
$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] Wait until it shuts down."
Add-Content -Path $logPath -Value $report
Write-Host $report
Sleep 5
while( (Get-VM -VMName $VMName).Uptime.TotalSeconds -gt 20 )
{
  Write-Host "Still awaiting Shutdown"
  Sleep 3
}

$report = "[$now] Now wait until it has been up for 30 seconds. Sleeping 5 seconds"
Add-Content -Path $logPath -Value $report
Write-Host $report
Sleep 5
while( (Get-VM -VMName $VMName).Uptime.TotalSeconds -lt 30 )
{
  Write-Host "peaking towards 30..."
  Sleep 3
}

$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] $VMName is awake and up for 30 seconds. Next step."
Add-Content -Path $logPath -Value $report
Write-Host $report

#Step Two

$stepTwo = {
  Write-Host "Password = $args"
  $securePass = ConvertTo-SecureString -String "$args" -AsPlainText -Force
  Install-HgsServer -HgsDomainName "shielded.com" -SafeModeAdministratorPassword $securePass -Restart
}
Invoke-Command -ComputerName $ipv4 -Credential $cred -ScriptBlock $stepTwo -ArgumentList $adminPassword

$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] Finished STEP TWO. Sleeping 5 seconds and Wait until it shuts down."
Add-Content -Path $logPath -Value $report
Write-Host $report
Sleep 5
while( (Get-VM -VMName $VMName).Uptime.TotalSeconds -gt 20 )
{
  Write-Host "Still awaiting Shutdown"
  Sleep 3
}

$report = "[$now] Now wait until it has been up for 90 seconds. Sleeping 5 seconds"
Add-Content -Path $logPath -Value $report
Write-Host $report
Sleep 5
while( (Get-VM -VMName $VMName).Uptime.TotalSeconds -lt 90 )
{
  Write-Host "peaking towards 90..."
  Sleep 3
}
$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] $VMName is awake and up for NINETY seconds. Next step."
Add-Content -Path $logPath -Value $report
Write-Host $report


$password = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force
$shieldedCred = New-Object System.Management.Automation.PSCredential -ArgumentList "shielded\Administrator, $password"

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

$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] $VMName is Maybe going to spit."
Add-Content -Path $logPath -Value $report
Write-Host $report
Invoke-Command -ComputerName $ipv4 -Credential $shieldedCred -ScriptBlock $stepThree -ArgumentList $adminPassword

$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] $VMName is gonna try again."
Add-Content -Path $logPath -Value $report
Write-Host $report
Invoke-Command -ComputerName $ipv4 -Credential $shieldedCred -ScriptBlock $stepThree -ArgumentList $adminPassword

$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] $VMName is ready to add the group item."
Add-Content -Path $logPath -Value $report
Write-Host $report

$stepFour = {
  $name = 'Guarded Hosts'
  New-ADGroup -Name $name -GroupScope Global -GroupCategory Security
  $group = Get-ADGroup $name
  Add-HgsAttestationHostGroup -Name $group.Name -Identifier $group.SID 
}
$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] $VMName is configured."
Add-Content -Path $logPath -Value $report
Write-Host $report

Invoke-Command -ComputerName $ipv4 -Credential $shieldedCred -ScriptBlock $stepFour

$now = [System.DateTime]::Now.ToLongTimeString()
$report = "[$now] $VMName finished detailed diagnostics."
Add-Content -Path $logPath -Value $report
Write-Host $report
Invoke-Command -ComputerName $ipv4 -Credential $shieldedCred -ScriptBlock { Get-HgsTrace -RunDiagnostics -Detailed }