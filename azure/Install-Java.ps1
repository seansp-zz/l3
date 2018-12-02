Import-Module C:\users\public\Microsoft.LSG.Utilities.psm1 -Force
Start-LSGNotes -path c:\users\public\Install-Java.log
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}

Write-LSGNote "Downloading the Java installer."
Set-Location -Path c:\users\public
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
wget https://javadl.oracle.com/webapps/download/AutoDL?BundleId=235725_2787e4a523244c269598db4e85c51e0c -OutFile ./Install-Java8.exe
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}


$config = 
"
INSTALL_SILENT=Enable
INSTALLDIR=C:\java\jre
WEB_JAVA_SECURITY_LEVEL=H
"
Write-LSGNote "Creating Java.Config"
Set-Content java.config -Value $config
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
Write-LSGNote "Installing Java..."
./Install-Java8.exe INSTALLCFG=c:\users\public\java.config /L c:\users\public\Java-Installation-Log.log
if( -not $? )
{
    $issue = $Error[0].Exception.Message
    Write-LSGNote "ERROR::$issue"
}
