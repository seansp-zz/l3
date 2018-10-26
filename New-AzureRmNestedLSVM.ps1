Param(
    [Parameter(Mandatory=$true)][string] $ResourceGroupName,
    [Parameter(Mandatory=$true)][string] $Location,
#    [Parameter(Mandatory=$true)][string] $TemplatePath,
#    [Parameter(Mandatory=$true)][string] $ParametersPath,
    [Parameter(Mandatory=$true)][string] $AdminUsername,
    [Parameter(Mandatory=$true)][string] $AdminPassword,
    [Parameter(Mandatory=$true)][string] $AzureStorageKey
)

$securePassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force


$Global:startTime = [System.DateTime]::Now
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

Write-Note "Creating RG:$ResourceGroupName in $Location"
New-AzureRmResourceGroup -Name "$ResourceGroupName" -Location "$Location"
#Create a temporary file with the populated parameters.
Write-Note "Loading default parameters...."
$parameters = Get-Content -Path .\ps.parameters.json
Write-Note "Replacing 'resourceLocation' with '$Location'"
$updatedParameters = $parameters -replace "resourceGroupName", "$ResourceGroupName"
Set-Content -Path .\$ResourceGroupName.json -Value $updatedParameters
Write-Note "Creating host srv16 in $ResourceGroupName"
New-AzureRmResourceGroupDeployment -Name "LSVM-$ResourceGroupName" -ResourceGroupName "$ResourceGroupName" `
  -TemplateFile .\ps.template.json -adminPassword $securePassword -location $Location `
  -resourceGroupNameFromTemplate $ResourceGroupName -TemplateParameterFile ".\$ResourceGroupName.json" -ErrorAction Stop

Write-Note "Now the VM has been deployed."

Write-Note "Using Custom Script Extensions to: Install Hyper-V using bootstrap from azure."
Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName `
    -VMName srv16 -Location $Location -FileUri "https://raw.githubusercontent.com/seansp/l3/master/Install-HyperV-Reboot.ps1" `
    -Run "Install-HyperV-Reboot.ps1" `
    -Name CustomScriptExtension

Write-Note "Installing NuGet/AzureRM via CustomScriptExtension."
Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName `
    -VMName srv16 -Location $Location -FileUri "https://raw.githubusercontent.com/seansp/l3/master/azuremodules.ps1" `
    -Run "azuremodules.ps1" `
    -Name CustomScriptExtension

Write-Note "Installing Networking settings."
Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName `
    -VMName srv16 -Location $Location -FileUri "https://raw.githubusercontent.com/seansp/l3/master/networkingv2.ps1" `
    -Run "networkingv2.ps1" `
    -Name CustomScriptExtension

Write-Note "Retrieving TBD image from Azure."
Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName `
    -VMName srv16 -Location $Location -FileUri "https://raw.githubusercontent.com/seansp/l3/master/copy_TBD_from_azure.ps1" `
    -Run "copy_TBD_from_azure.ps1" `
    -Argument  "$AzureStorageKey" `
    -Name CustomScriptExtension

Write-Note "Retrieving Guarded Host image from Azure."
Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName `
    -VMName srv16 -Location $Location -FileUri "https://raw.githubusercontent.com/seansp/l3/master/copy_GuardedHostBase_from_azure.ps1" `
    -Run "copy_GuardedHostBase_from_azure.ps1" `
    -Argument  "$AzureStorageKey" `
    -Name CustomScriptExtension

Write-Note "Retrieving tool scripts."
Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName `
    -VMName srv16 -Location $Location -FileUri "https://raw.githubusercontent.com/seansp/l3/master/tools/Get-Tools.ps1" `
    -Run "Get-Tools.ps1" `
    -Name CustomScriptExtension


Write-Note "Starting scheduled task to Build Nested LSVM now."
$taskArgs = "-HGSName NestedHGS -hgsMem 4GB -switchName IntSwitch -Domain shielded -adminPassword $AdminPassword -GhostName GuardedHost -GhostMem 8GB"
Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName `
    -VMName srv16 -Location $Location -FileUri "c:\users\public\Schedule-Build-NestedLSVM.ps1" `
    -Run "C:\users\public\schedule-build-NestedLSVM.ps1" -Argument $taskArgs -Name CustomScriptExtension



Write-Note "Finished."