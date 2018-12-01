Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name GuardedFabricTools -Repository PSGallery -Force
Install-WindowsFeature -Name Hyper-V, HostGuardian -IncludeManagementTools -Restart