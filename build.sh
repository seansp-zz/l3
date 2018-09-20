#!/bin/bash
echo "Creating <$1> in Region <$2>"
az group create -g $1 -l $2
sed -e "s/resourceGroupName/$1/g" template.json > $1.json
az group deployment create --resource-group $1 --template-file ./$1.json --parameters ./parameters.json --parameters adminPassword=p@ssw0rd1234 location=$2
az vm list -g $1 --show-details | grep publicIps
az vm extension set --resource-group $1 --vm-name srv16 --name CustomScriptExtension --publisher Microsoft.Compute --settings '{"fileUris":["https://raw.githubusercontent.com/charlieding/Virtualization-Documentation/live/hyperv-tools/Nested/NVMBootstrap_WinServer16.ps1"], "commandToExecute":"powershell.exe ./NVMBootstrap_WinServer16.ps1"}'

