# Get all Azure AD applications
$apps = Get-AzureADApplication -All $true

# Create a list to store app details
$appList = @()

# Loop through each app and get its URLs
foreach ($app in $apps) {
    $appUrls = $app.IdentifierUris
    $appDetails = [PSCustomObject]@{
        'DisplayName' = $app.DisplayName
        'AppUrls' = $appUrls -join ','
    }
    $appList += $appDetails
}

# Export app details to CSV
$appList | Export-Csv -Path 'C:\Temp\AzureADAppUrls.csv' -NoTypeInformation