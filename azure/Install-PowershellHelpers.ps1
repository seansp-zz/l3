$toolRoot = "https://raw.githubusercontent.com/seansp/l3/master/azure"

$tools = @()
$tools += "Microsoft.LSG.Utilities.psm1"
foreach( $tool in $tools )
{
    wget $toolRoot/$tool -Outfile c:\users\public\$tool
}