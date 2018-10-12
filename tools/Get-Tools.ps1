Write-Host "Retrieving Tools from l3"
$toolRoot = "https://raw.githubusercontent.com/seansp/l3/master/tools"
$tools = @()
$tools += "Build-HGS.ps1"
$tools += "Build-GuardedHost.ps1"
$tools += "Schedule-Build-HGS.ps1"
foreach( $tool in $tools )
{
    Write-Host "Retrieving $tool to local folder."
    $src = wget $toolRoot/$tool
    Set-Content -Path C:\Users\Public\$tool -Value $src
}
Write-Host "Finished."