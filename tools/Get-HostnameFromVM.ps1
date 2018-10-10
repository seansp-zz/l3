Param( 
    [Parameter(Mandatory=$true)][string] $vmName 
)
$ips = Get-VM -VMName $vmName | Get-VMNetworkAdapter | Select IPAddresses
$ipv4 = $ips.IPAddresses[0]
$password = ConvertTo-SecureString -String "AUTOMATION_PASSWORD" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList "AUTOMATION_USERNAME", $password
Invoke-Command -ComputerName $ipv4 -ScriptBlock {hostname} -Credential $cred