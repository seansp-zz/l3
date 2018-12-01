$password = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $($args[1]), $password

$script = {
    $name = 'Guarded Hosts'
    New-ADGroup -Name $name -GroupScope Global -GroupCategory Security
    $group = Get-ADGroup $name
    Add-HgsAttestationHostGroup -Name $group.Name -Identifier $group.SID
}
Invoke-Command -ComputerName localhost -Credential $cred -ScriptBlock $script