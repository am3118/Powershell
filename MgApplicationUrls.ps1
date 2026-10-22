# Connect to Microsoft Graph
#Connect-MgGraph -Scopes "Application.Read.All"
# Get all Azure AD applications
$apps = Get-MgApplication -All

# Create a list to store app details
$appList = @()

# Loop through each app and get its URLs
foreach ($app in $apps) {
    $appUrls = $app.Web.RedirectUris
    $appDetails = [PSCustomObject]@{
        'DisplayName' = $app.DisplayName
        'AppUrls' = $appUrls -join ','
    }
    $appList += $appDetails
}

# Export app details to CSV
$appList | Export-Csv -Path 'C:\Temp\MgApplicationUrls.csv' -NoTypeInformation