$securePass = ConvertTo-SecureString -String "$args" -AsPlainText -Force
Install-HgsServer -HgsDomainName "myHgs.com" -SafeModeAdministratorPassword $securePass -Restart
