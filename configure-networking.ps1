## First create the internal switch.
New-VMSwitch -SwitchName "IntSwitch" -SwitchType Internal
$switchAdapter = Get-NetAdapter | Where-Object {$_.ifAlias -eq "vEthernet (IntSwitch)"}
$ifIndex = $switchAdapter.ifIndex
New-NetIPAddress -IPAddress 192.168.0.1 -PrefixLength 24 -InterfaceIndex $ifIndex
# Configure the NAT.
New-NetNat -Name "myNATnet" -InternalIPInterfaceAddressPrefix 192.168.0.0/24
# Turn on PING
netsh advfirewall firewall add rule name="ICMP Allow incoming V4 echo request" protocol=icmpv4:8,any dir=in action=allow
# Enable DNS
Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses ("192.168.0.1")
