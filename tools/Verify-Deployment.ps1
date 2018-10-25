$global:startTime = [DateTime]::Now 

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
function Write-Note {
    Param(
        [Parameter(Mandatory=$true)][string] $Message,
        [System.ConsoleColor] $color = [System.ConsoleColor]::DarkYellow
    )
    $now = [System.DateTime]::Now - $global:startTime
#    if( $global:logPath ) { Add-Content -Path $global:logPath -Value "[$now] $Message" }
    Write-Host -ForegroundColor DarkCyan -NoNewline [
    Write-Host -NoNewline $now -ForegroundColor DarkGreen
    Write-Host -NoNewline -ForegroundColor DarkCyan "] "
    Write-Host -ForegroundColor $color $Message
}
Write-Note "### Verifying successful deployment..."
Write-Note "Hgs Deployment Log ..."
Get-Content c:\users\public\hgs.deploy.log
Write-Note "GUARDED Host Deployment LOG ..."
Get-Content c:\users\public\guardedHost.deploy.log
$cred = Get-Credential -UserName "mstest" -Message "Admin Password for Guarded Host"
$sb_verifyGuardedHost = {
    hostname
    Get-HgsClientConfiguration
}
$ghost = Get-IP-From-VmName GuardedHost
Write-Note "Connecting to: GuardedHost -- $ghost"
Invoke-Command -ComputerName $ghost -Credential $cred -ScriptBlock $sb_verifyGuardedHost


Write-Host "Press ENTER to Close."
$input = Read-Host