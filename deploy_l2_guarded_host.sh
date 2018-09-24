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
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Copying 17744 onto test environment $1"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/copy_17744_from_azure.ps1"], "commandToExecute":"Powershell -File ./copy_17744_from_azure.ps1 \"AZURESTORAGEKEY\""}'
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/networkingv2.ps1"], "commandToExecute":"Powershell -File ./networkingv2.ps1"}'
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/startup_run_guarded_host_17744.ps1"], "commandToExecute":"Powershell -File ./startup_run_guarded_host_17744.ps1"}'
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Finished."


