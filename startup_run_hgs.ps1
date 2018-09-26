New-VM -Name HGS -MemoryStartupBytes 4GB -Generation 2 -VHDPath "C:\Users\Public\HGS-17744.vhdx" -BootDevice "VHD" -Switch "IntSwitch" -Path "C:\Virtual Machines\HGS"
Start-VM -Name HGS

