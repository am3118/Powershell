# Define a list of users
$text="C:\Scripts\slackusers.txt"
$users = Get-Content -Path $text  # Add your list of users here

# Iterate through the list of users
foreach ($user in $users) {
    # Get the user object
    $userObj = Get-AzureADUser -ObjectId $user
    
    # Get the registered devices for the user
    $devices = Get-AzureADUserRegisteredDevice -ObjectId $userObj.ObjectId
    
    # Output the devices
    Write-Host "Registered devices for $($userObj.UserPrincipalName):"
    $devices | Select-Object -Property DisplayName, DeviceOSType, ApproximateLastLogonTimeStamp
    Write-Host
}