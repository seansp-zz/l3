$securePass = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
$hgs_signer_cert = New-SelfSignedCertificate -FriendlyName "HGS Signer" -DnsName "$($args[1]).com"
$hgs_encrypt_cert = New-SelfSignedCertificate -FriendlyName "HGS Encrypt" -DnsName "$($args[1]).com"
New-Item -Path "C:\PFX" -ItemType Directory
Export-PfxCertificate -FilePath "C:\PFX\HGS_Signer.pfx" -Cert $hgs_signer_cert -Password $securePass -Force
Export-PfxCertificate -FilePath "C:\PFX\HGS_Encrypt.pfx" -Cert $hgs_encrypt_cert -Password $securePass -Force
Initialize-HgsServer -LogDirectory "C:\PFX" -HgsServiceName HGS -Http -TrustActiveDirectory -SigningCertificatePath C:\PFX\HGS_Signer.pfx -SigningCertificatePassword $securePass -EncryptionCertificatePath "C:\PFX\HGS_Encrypt.pfx" -EncryptionCertificatePassword $securePass

Disable-HgsAttestationPolicy Hgs_IommuEnabled
$name = 'Guarded Hosts'
New-ADGroup -Name $name -GroupScope Global -GroupCategory Security
$group = Get-ADGroup $name
Add-HgsAttestationHostGroup -Name $group.Name -Identifier $group.SID 
