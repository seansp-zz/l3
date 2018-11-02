Param(
    [Parameter(mandatory=$false)]  [string] $HGSName = "NestedHGS",
    [Parameter(mandatory=$false)] [Int64]  $hgsMem = 4GB,
    [Parameter(mandatory=$false)] [string]  $switchName = "IntSwitch",
    [Parameter(mandatory=$false)] [string] $Domain = "shielded",
    [Parameter(mandatory=$false)] [string] $adminUsername = "mstest",
    [Parameter(mandatory=$true)]  [string] $adminPassword,
    [Parameter(mandatory=$false)]  [string] $GhostName = "GuardedHost",
    [Parameter(mandatory=$false)] [Int64]  $GhostMem = 8GB
)

#TODO: Need to install my module so that I don't load it like this.
#TODO: Install won't correct my output path.  Temp 'HACK' is to change my folder.
#      This should be replaced with a query to get the run location from the library.
Set-Location -Path c:\users\public
Import-Module ./HyperV-DeployTestEnvironment.psm1 -Force -Global
Start-Notes ./LSVM.deploy.log

$cred = Get-NewPSCred $adminUsername $adminPassword
$shieldCred = Get-NewPSCred "$Domain\Administrator" $adminPassword

Write-Note "Starting with the Host Guardian Service on $HGSName"
#Build-HGS
Write-Note "Building the VM for $HGSName"
$hgsVhd = Build-NewVHDDelta -pathToSource C:\Users\Public\HGS.vhdx -vmName $HGSName
Build-NewVM -VMName $HGSName -pathToVHD $hgsVhd -memorySize $hgsMem -switchName $switchName
Write-Note "Turning on TPM with KeyProtector for $HGSName"
$guardian = Get-HgsGuardian -Name "myGuardian"
if( !$guardian )
{
    $guardian = New-HgsGuardian -Name "myGuardian" -GenerateCertificates
}
$keyProtector = New-HgsKeyProtector -Owner $guardian -AllowUntrustedRoot
Set-VMKeyProtector -VMName $HGSName -KeyProtector $keyProtector.RawData
Enable-VMTPM -VMName $HGSName
Write-Note "Starting $HGSName"
Start-VM $HGSName

Wait-UntilVMUptime $HGSName 30
$hgsip = Get-IPFromVmName $HGSName
Write-Note "Adding $hgsip for $HGSName to Trusted Hosts."
Add-ToTrustedHosts $hgsip

Write-Note "Renaming the VM to $HGSName"
Invoke-Command -ComputerName $hgsip -ScriptBlock {Rename-Computer -NewName "$args" -Restart -Force} -Credential $cred -ArgumentList $HGSName
Wait-UntilVMShutsDown $HGSName

Wait-UntilVMUptime $HGSName 30
Write-Note "Installing HostGuardianServiceRole and HgsServer for '$Domain.com'"
$hgsInstallHGSServer = {
  Install-WindowsFeature HostGuardianServiceRole -IncludeManagementTools
  $securePass = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
  Install-HgsServer -HgsDomainName "$($args[1]).com" -SafeModeAdministratorPassword $securePass -Restart
}
Invoke-Command -ComputerName $hgsip -Credential $cred -ScriptBlock $hgsInstallHGSServer -ArgumentList $adminPassword, $Domain
Wait-UntilVMShutsDown $HGSName

Wait-UntilVMUptime $HGSName 90
Write-Note "Creating certificates and Initializing the HgsServer"
$hgsInitializeHgsServer = {
  $securePass = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
  $hgs_signer_cert = New-SelfSignedCertificate -FriendlyName "HGS Signer" -DnsName "$($args[1]).com"
  $hgs_encrypt_cert = New-SelfSignedCertificate -FriendlyName "HGS Encrypt" -DnsName "$($args[1]).com"
  New-Item -Path "C:\PFX" -ItemType Directory
  Export-PfxCertificate -FilePath "C:\PFX\HGS_Signer.pfx" -Cert $hgs_signer_cert -Password $securePass -Force
  Export-PfxCertificate -FilePath "C:\PFX\HGS_Encrypt.pfx" -Cert $hgs_encrypt_cert -Password $securePass -Force
  Initialize-HgsServer -LogDirectory "C:\PFX" -HgsServiceName HGS -Http -TrustActiveDirectory -SigningCertificatePath C:\PFX\HGS_Signer.pfx -SigningCertificatePassword $securePass -EncryptionCertificatePath "C:\PFX\HGS_Encrypt.pfx" -EncryptionCertificatePassword $securePass
}
Invoke-Command -ComputerName $hgsip -Credential $shieldCred -ScriptBlock $hgsInitializeHgsServer -ArgumentList $adminPassword, $Domain
Invoke-Command -ComputerName $hgsip -Credential $shieldCred -ScriptBlock $hgsInitializeHgsServer -ArgumentList $adminPassword, $Domain

Write-Note "Turning off IOMMU attestation requirement.  Adding HgsAttestationHostGroup"
$hgsDisableIommu = {
  Disable-HgsAttestationPolicy Hgs_IommuEnabled
  $name = 'Guarded Hosts'
  New-ADGroup -Name $name -GroupScope Global -GroupCategory Security
  $group = Get-ADGroup $name
  Add-HgsAttestationHostGroup -Name $group.Name -Identifier $group.SID 
}
Invoke-Command -ComputerName $hgsip -Credential $shieldCred -ScriptBlock $hgsDisableIommu
#Build Guarded Host

$ghostvhd = Build-NewVHDDelta -pathToSource C:\Users\Public\GuardedHostBase.vhdx -vmName $GhostName
Build-NewVM -VMName $GhostName -pathToVHD $ghostvhd -memorySize $GhostMem -switchName $switchName

Write-Note "Turning on Virtualiztion Extensions for $GhostName"
Set-VMProcessor -VMName $GhostName -ExposeVirtualizationExtensions $true

Write-Note "Turning on TPM with KeyProtector for $GhostName"
#TODO: Do I really need a second one? What does this impact?  Seems fine reusing.
$keyProtector = New-HgsKeyProtector -Owner $guardian -AllowUntrustedRoot
Set-VMKeyProtector -VMName $GhostName -KeyProtector $keyProtector.RawData
Enable-VMTPM -VMName $GhostName
Write-Note "Starting $GhostName"
Start-VM $GhostName
#ToDO: How do I know it is ready for networking?
Wait-UntilVMUptime $GhostName 45
$ghostip = Get-IPFromVmName $GhostName
Write-Note "Got $GhostName at $ghostip"
Add-ToTrustedHosts $ghostip
Write-Note "Renaming the VM to $GhostName"
Invoke-Command -ComputerName $ghostip -ScriptBlock {Rename-Computer -NewName "$args" -Restart -Force} -Credential $cred -ArgumentList $GhostName
Wait-UntilVMShutsDown $GhostName 
Wait-UntilVMUptime $GhostName 30

Write-Note "Adding Hyper-V, HostGuardian and ManagementTools"
$ghostInstallWindowsFeature = { 
  Install-WindowsFeature -Name Hyper-V, HostGuardian -IncludeManagementTools -Restart
  }
Invoke-Command -ComputerName $ghostip -Credential $cred -ScriptBlock $ghostInstallWindowsFeature
Wait-UntilVMShutsDown $ghostName
Wait-UntilVMUptime $ghostName 31
Write-Note "Waiting until $ghostName reboots again."
Wait-UntilVMShutsDown $ghostName
Wait-UntilVMUptime $ghostName 30
#VM will shut down a second time.

Write-Note "Upgrading NuGet, GuardedFabricTools on $GhostName"
$ghostInstallModuleFabric = {
  Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
  Install-Module -Name GuardedFabricTools -Repository PSGallery -Force
}
Invoke-Command -ComputerName $ghostip -Credential $cred -ScriptBlock $ghostInstallModuleFabric

Write-Note "Setting dns to $hgsip for $hgsName on $GhostName"
$ghostAddDNS = {
  netsh interface ipv4 set dnsservers 'Ethernet 2' static $args primary
}
Invoke-Command -ComputerName $ghostip -Credential $cred -ScriptBlock $ghostAddDNS -ArgumentList $hgsip

Write-Note "Adding $GhostName to '$Domain.com' domain"
$ghostJoinDomain = {
  $password = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
  $cred = New-Object System.Management.Automation.PSCredential -ArgumentList $($args[1]), $password
  Add-Computer -DomainName "$($args[2]).com" -Credential $cred -Restart
}
Invoke-Command -ComputerName $ghostip -Credential $cred -ScriptBlock $ghostJoinDomain -ArgumentList $adminPassword, "$Domain\Administrator", $Domain
Wait-UntilVMShutsDown $GhostName
Wait-UntilVMUptime $GhostName 90

Write-Note "Adding $GHostName to 'Guarded Hosts' group on $HGSName"
$hgsAddMember = {
  Add-ADGroupMember "Guarded Hosts" -Members $args$ 
}
Invoke-Command -ComputerName $hgsip -Credential $shieldCred -ScriptBlock $hgsAddMember -ArgumentList $GhostName

Write-Note "Turning off DeviceGuard as a PlatformSecurityFeature."
$ghostDisableDeviceGuard = {
  Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\ -Name RequirePlatformSecurityFeatures -Value 0
  Restart-Computer -Force
}
Invoke-Command -ComputerName $ghostip -Credential $cred -ScriptBlock $ghostDisableDeviceGuard
Wait-UntilVMShutsDown $GhostName
Wait-UntilVMUptime $GhostName 90

Write-Note "Configuring attestation Client Configuration on $ghostName"
$ghostHgsClientConfiguration = { 
    Set-HgsClientConfiguration -AttestationServerUrl "http://hgs.$args.com/Attestation" -KeyProtectionServerUrl "http://hgs.$args.com/KeyProtection"
  }
Invoke-Command -ComputerName $ghostip -Credential $shieldCred -ScriptBlock $ghostHgsClientConfiguration -ArgumentList $Domain
Write-Note "All Done."