Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
Start-LSGNotes -path c:\users\public\ConfigureHGS-Step4.log
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

$script = {
    Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
    Start-LSGNotes -path c:\users\public\ConfigureHGS-Step4.localhost.log
    $name = 'Guarded Hosts'

    Write-LSGNote "Adding the ADGroup $name"
    New-ADGroup -Name $name -GroupScope Global -GroupCategory Security
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }
    Write-LSGNote "Retrieving created group."
    $group = Get-ADGroup $name
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }
    Write-LSGNote "Adding group to HgsAttestationHostGroup"
    Add-HgsAttestationHostGroup -Name $group.Name -Identifier $group.SID
    if( -not $? )
    {
        $issue = $Error[0].Exception.Message
        Write-LSGNote "ERROR::$issue"
    }
}
Write-LSGNote "Invoke on localhost"
Invoke-Command -ComputerName localhost -Credential $cred -ScriptBlock $script
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
