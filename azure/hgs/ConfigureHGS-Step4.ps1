Disable-HgsAttestationPolicy Hgs_IommuEnabled
$name = 'Guarded Hosts'
New-ADGroup -Name $name -GroupScope Global -GroupCategory Security
$group = Get-ADGroup $name
Add-HgsAttestationHostGroup -Name $group.Name -Identifier $group.SID