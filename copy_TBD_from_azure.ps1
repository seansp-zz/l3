$mine = New-AzureStorageContext -StorageAccountName mule -StorageAccountKey "$args"
$blob = Get-AzureStorageBlob -Context $mine -Container vhdx | Where-Object {$_.Name -eq "TBD.Server2019.17744.vhdx"}
Get-AzureStorageBlobContent -Blob $blob.Name -Context $mine -Container vhdx -Destination C:\Users\Public\HGS.vhdx
