# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.Read.All", "UserAuthenticationMethod.Read.All"

# Read user list from text file
$users = Get-Content -Path "C:\scripts\cwddeviceownerupn.txt"

$results = @()

foreach ($user in $users) {
    $phoneInfo = Get-MgUserAuthenticationPhoneMethod -UserId $user
    
    $result = [PSCustomObject]@{
        UserPrincipalName = $user
        PhoneNumber = $phoneInfo.PhoneNumber
        PhoneType = $phoneInfo.PhoneType
    }
    
    $results += $result
}

# Export results to CSV
$results | Export-Csv -Path "C:\scripts\CWDdeviceUserMFAPhoneNumbers.csv" -NoTypeInformation
