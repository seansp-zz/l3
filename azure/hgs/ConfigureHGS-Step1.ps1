Install-WindowsFeature HostGuardianServiceRole -IncludeManagementTools
$securePass = ConvertTo-SecureString -String "$($args[0])" -AsPlainText -Force
Install-HgsServer -HgsDomainName "$($args[1]).com" -SafeModeAdministratorPassword $securePass -Restart