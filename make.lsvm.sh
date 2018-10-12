#!/bin/bash
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Creating <$1> in Region <$2>"
az group create -g $1 -l $2
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Finished creating group. Deploying..."
sed -e "s/resourceGroupName/$1/g" template.json > $1.json
az group deployment create --resource-group $1 --template-file ./$1.json --parameters ./parameters.json --parameters adminPassword=p@ssw0rd1234 location=$2
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Finished, getting IP."
az vm list -g $1 --show-details | grep publicIps
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Installing Hyper-V"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/charlieding/Virtualization-Documentation/live/hyperv-tools/Nested/NVMBootstrap_WinServer16.ps1"], "commandToExecute":"powershell.exe ./NVMBootstrap_WinServer16.ps1"}'
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Updating NuGet to at least 2.8.5.201 on $1"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"commandToExecute":"Powershell -C \"Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force\""}'
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Installing AzureRM Powershell Module on $1"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"commandToExecute":"Powershell -C \"Install-Module -Name AzureRM -Force\""}'
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Configuring the networking for Host $1"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/networkingv2.ps1"], "commandToExecute":"Powershell -File ./networkingv2.ps1"}'
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Retrieving HGS image from Azure Storage Account -- MULE"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/copy_TBD_from_azure.ps1\"], \"commandToExecute\":\"Powershell -File ./copy_TBD_from_azure.ps1 \\\"$3\\\"\"}"
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Retrieving GuardedHost image from Azure Storage Account -- MULE"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/copy_GuardedHostBase_from_azure.ps1\"], \"commandToExecute\":\"Powershell -File ./copy_GuardedHostBase_from_azure.ps1 \\\"$3\\\"\"}"
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Getting tools."
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/tools/Get-Tools.ps1"], "commandToExecute":"Powershell -File ./Get-Tools.ps1"}'
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Starting task to Build HGS."
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"commandToExecute\":\"Powershell -File c:/users/public/Schedule-Build-HGS.ps1 -VMName HGS -adminUsername $4 -adminPassword $5\"}"
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Finished."

