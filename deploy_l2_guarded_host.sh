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

#printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Adding Host Guardian Service to the Server 2016 L1 instance."
#az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"commandToExecute":"Powershell -C \"Install-WindowsFeature HostGuardianServiceRole -IncludeManagementTools -Restart\""}'
#printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Configuring the Host Guardian Service."
#az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/configureHGS.ps1"], "commandToExecute":"Powershell -File ./configureHGS.ps1 \"WINPASSWORD\""}'

printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Copying HGS into test environment $1"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/copy_HGS17744_from_azure.ps1"], "commandToExecute":"Powershell -File ./copy_HGS17744_from_azure.ps1 \"AZURESTORAGEPASSWORD\""}'
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Copying Guarded Host onto test environment $1"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/copy_GuardedHost17744_from_azure.ps1"], "commandToExecute":"Powershell -File ./copy_GuardedHost17744_from_azure.ps1 \"AZURESTORAGEPASSWORD\""}'
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Configuring the networking for Host $1"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/networkingv2.ps1"], "commandToExecute":"Powershell -File ./networkingv2.ps1"}'
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Starting up the HGS $1"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/startup_run_hgs.ps1"], "commandToExecute":"Powershell -File ./startup_run_hgs.ps1"}'
printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Starting up the Guarded Host $1"
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/seansp/l3/master/startup_run_guarded_host_17744.ps1"], "commandToExecute":"Powershell -File ./startup_run_guarded_host_17744.ps1"}'

printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "Finished."


