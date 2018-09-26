$mine = New-AzureStorageContext -StorageAccountName seansp -StorageAccountKey "$args"
$blob = Get-AzureStorageBlob -Context $mine -Container vhdx | Where-Object {$_.Name -eq "Windows_InsiderPreview_ServerStandard_VHDX_17744.vhdx"}
Get-AzureStorageBlobContent -Blob $blob.Name -Context $mine -Container vhdx -Destination C:\Users\Public\Windows_InsiderPreview_ServerStandard_VHDX_17744.vhdx
