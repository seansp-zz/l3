Param( [Parameter(Mandatory=$true)][string] $userName, 
       [Parameter(Mandatory=$true)][string] $password )

Write-Host "Retrieving Tools from l3"
$toolRoot = "https://raw.githubusercontent.com/seansp/l3/master/tools"
$tools = @()
$tools += "Get-TrustedHosts.ps1"
$tools += "Get-VMs.ps1"
$tools += "Get-HostnameFromVM.ps1"
$tools += "Build-HGS.ps1"
$tools += "Build-GuardedHost.ps1"
foreach( $tool in $tools )
{
    Write-Host "Retrieving $tool to local folder."
    $src = wget $toolRoot/$tool
    $src = $src -replace "AUTOMATION_USERNAME", $userName
    $src = $src -replace "AUTOMATION_PASSWORD", $password
    Set-Content -Path C:\Users\Public\$tool -Value $src
}
Write-Host "Finished."