Set-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\ -Name RequirePlatformSecurityFeatures -Value 0
Restart-Computer -Force