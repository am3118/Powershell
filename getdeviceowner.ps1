# Connect to Azure AD
Connect-AzureAD

# Get all Hybrid Azure AD joined devices
$hybridDevices = Get-AzureADDevice -All $true | Where-Object { $_.DeviceTrustType -eq "ServerAd" }

# Create an array to store the results
$results = @()

# Loop through each device and get its owner
foreach ($device in $hybridDevices) {
    $owner = Get-AzureADDeviceRegisteredOwner -ObjectId $device.ObjectId
    
    $result = [PSCustomObject]@{
        DeviceName = $device.DisplayName
        DeviceId = $device.DeviceId
        Owner = if ($owner) { $owner.DisplayName } else { "N/A" }
        OwnerUPN = if ($owner) { $owner.UserPrincipalName } else { "N/A" }
        LastLogonTimestamp = $device.ApproximateLastLogonTimestamp
    }
    
    $results += $result
}

# Display the results
$results | Format-Table -AutoSize

# Optionally, export to CSV
$results | Export-Csv -Path "HybridDeviceOwners.csv" -NoTypeInformation
