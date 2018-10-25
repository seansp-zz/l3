Stop-VM NestedHGS -ErrorAction SilentlyContinue
Stop-VM GuardedHost -ErrorAction SilentlyContinue
Remove-VM NestedHGs -Force -ErrorAction SilentlyContinue
Remove-VM GuardedHost -Force -ErrorAction SilentlyContinue

Remove-Item C:\users\Public\GuardedHostBase.GuardedHost.vhdx -Force -ErrorAction SilentlyContinue
Remove-Item C:\users\Public\HGS.NestedHGS.vhdx -Force -ErrorAction SilentlyContinue

Remove-Item -Recurse -Path 'C:\Virtual Machines\GuardedHost' -Force -ErrorAction SilentlyContinue
Remove-ITem -Recurse -Path 'C:\Virtual Machines\NestedHGS' -FOrce -ErrorAction SilentlyContinue
