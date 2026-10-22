# Import the Azure AD module
Import-Module AzureAD

# Connect to Azure AD
Connect-AzureAD

# Read the list of device names from the text file
$deviceNames = Get-Content -Path "C:\scripts\cwddevicelist.txt"

# Initialize an array to store the results
$results = @()

# Loop through each device name
foreach ($deviceName in $deviceNames) {
    # Get the device information
    $device = Get-AzureADDevice -Filter "displayName eq '$deviceName'"
    
    if ($device) {
        # Create a custom object with the device information
        $deviceInfo = [PSCustomObject]@{
            DisplayName = $device.DisplayName
            ObjectId = $device.ObjectId
        }
        
        # Add the device info to the results array
        $results += $deviceInfo
    }
    else {
        Write-Warning "Device not found: $deviceName"
    }
}

# Display the results
$results | Format-Table -AutoSize

# Optionally, export the results to a CSV file
$results | Export-Csv -Path "C:\scripts\cwddeviceID.csv" -NoTypeInformation
