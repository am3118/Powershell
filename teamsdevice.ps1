# Authenticate to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All"

# Specify the user's UPN (User Principal Name)
$text="C:\Scripts\slackusers.txt"

$userUPN = Get-Content -Path $text # Replace with the user's actual UPN

# Retrieve sign-in logs for the user
$signInLogs = Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$userUPN'"

# Filter sign-in logs to find sign-ins related to Teams
$teamsSignIns = $signInLogs | Where-Object { $_.AppDisplayName -eq "Microsoft Teams" }

# Extract information about the device used for each sign-in
foreach ($signIn in $teamsSignIns) {
    $deviceId = $signIn.DeviceDetail.DeviceId
    $deviceDisplayName = $signIn.DeviceDetail.DisplayName
    $deviceOSType = $signIn.DeviceDetail.OperatingSystem
    
    Write-Host "Sign-in from device: $deviceDisplayName ($deviceId), OS: $deviceOSType"
}
