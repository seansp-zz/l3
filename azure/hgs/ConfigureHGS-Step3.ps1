Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
Start-LSGNotes -path c:\users\public\ConfigureHGS-Step3.log
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}

Write-LSGNote "building password"
$password = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
Write-LSGNote "building credential"
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $($args[1]), $password
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}


$script = 
{
    Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
    Start-LSGNotes -path c:\users\public\ConfigureHGS-Step3.localhost.log
    
    $securePass = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
    Write-LSGNote "Creating HGS Signer Certificate"
    $hgs_signer_cert = New-SelfSignedCertificate -FriendlyName "HGS Signer" -DnsName "$($args[1]).com"
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }
    Write-LSGNote "Creating HGS Encrypt Certificate"
    $hgs_encrypt_cert = New-SelfSignedCertificate -FriendlyName "HGS Encrypt" -DnsName "$($args[1]).com"
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }
    Write-LSGNote "Building PFX folder."
    New-Item -Path "C:\PFX" -ItemType Directory
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }
    Write-LSGNote "Export Signer Certificate..."
    Export-PfxCertificate -FilePath "C:\PFX\HGS_Signer.pfx" -Cert $hgs_signer_cert -Password $securePass -Force
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }
    Write-LSGNote "Export Encrypt Certificate..."
    Export-PfxCertificate -FilePath "C:\PFX\HGS_Encrypt.pfx" -Cert $hgs_encrypt_cert -Password $securePass -Force
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }

    Write-LSGNote "Initializing the HGSServer..."
    Initialize-HgsServer -LogDirectory "C:\PFX" -HgsServiceName HGS -Http -TrustActiveDirectory -SigningCertificatePath C:\PFX\HGS_Signer.pfx -SigningCertificatePassword $securePass -EncryptionCertificatePath "C:\PFX\HGS_Encrypt.pfx" -EncryptionCertificatePassword $securePass
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }
}
Write-LSGNote "Invoking localhost"
Invoke-Command -ComputerName localhost -Credential $cred -ScriptBlock $script -ArgumentList $args[0], $args[2] 
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
