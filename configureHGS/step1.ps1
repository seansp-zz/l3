$securePass = ConvertTo-SecureString -String "$args" -AsPlainText -Force
Install-HgsServer -HgsDomainName "shielded.com" -SafeModeAdministratorPassword $securePass -Restart