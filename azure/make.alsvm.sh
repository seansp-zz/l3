#!/bin/bash
echo "Making group.  DNSName=lsvmtst$5"
az group create --name $1 --location $2 
sed -e "s/REGION_NAME/$2/g" -e "s/RESOURCE_GROUP_NAME/$1/g" -e "s/DNS_PREFIX/lsvmtst$5/g" ./jenkins/parameters.json > ./jenkinsParameters.json
sed -e "s/REGION_NAME/$2/g" -e "s/RESOURCE_GROUP_NAME/$1/g" ./hgs/parameters.json > ./hgsParameters.json
sed -e "s/REGION_NAME/$2/g" -e "s/RESOURCE_GROUP_NAME/$1/g" ./guardedhost/parameters.json > ./guardedHostParameters.json

echo "-- Making Jenkins."
az group deployment create --name "DeployJenkins" --resource-group "$1" --template-file ./jenkins/template.json --parameters @./jenkinsParameters.json adminPassword=$3 > azure.$1.deploy.jenkins.json
JENKINS_JOBNAME="$(cat azure.$1.deploy.jenkins.json | jq -r '.name')"
JENKINS_RESULT="$(cat azure.$1.deploy.jenkins.json |jq -r '.properties.provisioningState')"
JENKINS_URL="$(cat azure.$1.deploy.jenkins.json |jq -r '.properties.outputs.jenkinsURL.value')"
JENKINS_SSH="$(cat azure.$1.deploy.jenkins.json |jq -r '.properties.outputs.ssh.value')"
echo "$JENKINS_JOBNAME -- $JENKINS_RESULT"

echo "-- Making the HGS"
az group deployment create --name "DeployHGS" --resource-group "$1" --template-file ./hgs/template.json --parameters @./hgsParameters.json adminPassword=$3
echo "-- Adding Microsoft.LSG.Utilities Module to HGS"
az vm extension set --resource-group $1 --vm-name myhgs --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/Install-PowershellHelpers.ps1\"], \"commandToExecute\":\"Powershell -File ./Install-PowershellHelpers.ps1\"}"

az vm extension set --resource-group $1 --vm-name myhgs --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/hgs/ConfigureHGS-Step1.ps1\"], \"commandToExecute\":\"Powershell -File ./ConfigureHGS-Step1.ps1 \\\"$3\\\" \\\"$4\\\"\"}"

echo "Making the Guarded Host"
az group deployment create --name "DeployGuardedHost" --resource-group "$1" --template-file ./guardedhost/template.json --parameters @./guardedHostParameters.json adminPassword=$3

echo "-- Adding Microsoft.LSG.Utilities Module to GuardedHost"
az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/Install-PowershellHelpers.ps1\"], \"commandToExecute\":\"Powershell -File ./Install-PowershellHelpers.ps1\"}"

az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"commandToExecute\":\"Powershell -C \\\"Install-WindowsFeature -Name Hyper-V, HostGuardian -IncludeManagementTools -Restart\\\"\"}"
az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"commandToExecute\":\"Powershell -C \\\"Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force\\\"\"}"
az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"commandToExecute\":\"Powershell -C \\\"Install-Module -Name GuardedFabricTools -Repository PSGallery -Force\\\"\"}"
az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/guardedhost/networkingv2.ps1\"], \"commandToExecute\":\"Powershell -File ./networkingv2.ps1\"}"

echo "Configuring the DNS... and joining domain."

HgsDNSIP="$(az vm list-ip-addresses -g $1 -n myHgs | sed -n '7p' | sed -e 's/\"//g' | tr -d '[:space:]')"
az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"commandToExecute\":\"netsh interface ipv4 set dnsservers Ethernet static $HgsDNSIP primary\"}"
az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/guardedhost/JoinDomain.ps1\"], \"commandToExecute\":\"Powershell -File ./JoinDomain.ps1 $3 $4\\mstest $4\"}"

echo "---------- The Domain Controller -- myHGS is up and a domain controller and attestation is configured."
echo "---------- The Guarded Host -- GuardedHost is up, has Hyper-V and Guardian Role, and has joined $4"

echo "---------- Now initializing the HGS."
az vm extension set --resource-group $1 --vm-name myhgs --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/hgs/ConfigureHGS-Step3.ps1\"], \"commandToExecute\":\"Powershell -File ./ConfigureHGS-Step3.ps1 $3 $4\\mstest $4\"}"
az vm extension set --resource-group $1 --vm-name myhgs --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/hgs/ConfigureHGS-Step4.ps1\"], \"commandToExecute\":\"Powershell -File ./ConfigureHGS-Step4.ps1 $3 $4\\mstest $4\"}"

echo "-- Adding Guarded Host to the AttestationHostGroup"
az vm extension set --resource-group $1 --vm-name myhgs --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/hgs/AddGroupMember.ps1\"], \"commandToExecute\":\"Powershell -File ./AddGroupMember.ps1 $3 $4\\mstest $4\"}"
echo "-- Disabling the DeviceGuard on the Guarded Host."
az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/guardedhost/DisableDeviceGuard.ps1\"], \"commandToExecute\":\"Powershell -File ./DisableDeviceGuard.ps1 $3 $4\\mstest $4\"}"

echo "-- Setting Attestation for Guarded Host"
az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/guardedhost/Configure-Attestation.ps1\"], \"commandToExecute\":\"Powershell -File ./Configure-Attestation.ps1 $3 $4\\mstest $4\"}"

echo "-- Installing Java on HGS"
az vm extension set --resource-group $1 --vm-name myHgs --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/Install-Java.ps1\"], \"commandToExecute\":\"Powershell -File ./Install-Java.ps1\"}"
echo "-- Installing Java on GuardedHost"
az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/Install-Java.ps1\"], \"commandToExecute\":\"Powershell -File ./Install-Java.ps1\"}"


echo "------- Installing OpenSSH on HGS"
az vm extension set --resource-group $1 --vm-name myhgs --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/Install-OpenSSHServer.ps1\"], \"commandToExecute\":\"Powershell -File ./Install-OpenSSHServer.ps1\"}"

echo "------- Installing OpenSSH on Guarded Host"
az vm extension set --resource-group $1 --vm-name guardedhost --name CustomScriptExtension --publisher Microsoft.Compute --settings "{\"fileUris\":[\"https://raw.githubusercontent.com/seansp/l3/master/azure/Install-OpenSSHServer.ps1\"], \"commandToExecute\":\"Powershell -File ./Install-OpenSSHServer.ps1\"}"


echo "--------------- DONE configuring HGS and Guarded Host."





myHGSIP="$(az vm list-ip-addresses -g $1 -n myHgs | grep ipAddress | sed -e 's/\"ipAddress\"://g' | tr -d '\"' | tr -d ',' | tr -d '[:space:]')"
GhostIP="$(az vm list-ip-addresses -g $1 -n GuardedHost | grep ipAddress | sed -e 's/\"ipAddress\"://g' | tr -d '\"' | tr -d ',' | tr -d '[:space:]')"
JenkinsIP="$(az vm list-ip-addresses -g $1 -n Jenkins | grep ipAddress | sed -e 's/\"ipAddress\"://g' | tr -d '\"' | tr -d ',' | tr -d '[:space:]')"




echo "The RG:$1 is up. Some manual steps are required."
echo "The Domain Controller 'myHGS' for $4.com -- $myHGSIP"
echo "The Guarded Host 'GuardedHost' -- $GhostIP"
echo "The Jenkins -- $JenkinsIP"

echo "JENKINS can be found here: $JENKINS_URL"
echo "To log in, use SSH tunneling -- $JENKINS_SSH"

