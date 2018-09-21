$mine = New-AzureStorageContext -StorageAccountName seansp -StorageAccountKey "$args"
$blobs = Get-AzureStorageBlob -Context $mine -Container vhdx | Select-Object -First 1
Get-AzureStorageBlobContent -Blob $blobs.Name -Context $mine -Container vhdx -Destination C:\Users\mstest