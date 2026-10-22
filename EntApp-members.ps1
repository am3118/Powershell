Connect-AzureAD
# Retrieve all Enterprise Applications
$EnterpriseApps = Get-AzureADServicePrincipal -All $true

# Initialize an array to store results
$ExportData = @()

# Loop through each Enterprise Application
foreach ($App in $EnterpriseApps) {
    # Get direct user assignments
    $UserAssignments = Get-AzureADServiceAppRoleAssignment -ObjectId $App.ObjectId | Where-Object {$_.PrincipalType -eq "User"}
    foreach ($User in $UserAssignments) {
        $ExportData += [PSCustomObject]@{
            ApplicationName = $App.DisplayName
            ApplicationId = $App.ObjectId
            PrincipalType = "User"
            PrincipalName = $User.UserPrincipalName
        }
    }

    # Get group assignments and their members
    $GroupAssignments = Get-AzureADServiceAppRoleAssignment -ObjectId $App.ObjectId | Where-Object {$_.PrincipalType -eq "Group"}
    foreach ($Group in $GroupAssignments) {
        $GroupDetails = Get-AzureADGroup -ObjectId $Group.PrincipalId
        $GroupMembers = Get-AzureADGroupMember -ObjectId $Group.PrincipalId | Where-Object {$_.ObjectType -eq "User"}
        foreach ($Member in $GroupMembers) {
            $ExportData += [PSCustomObject]@{
                ApplicationName = $App.DisplayName
                ApplicationId = $App.ObjectId
                PrincipalType = "Group Member"
                PrincipalName = "$($Member.UserPrincipalName) (via Group: $($GroupDetails.DisplayName))"
            }
        }
    }
}

# Export to CSV
$ExportData | Export-Csv -Path "c:\temp\EnterpriseApps_UsersAndGroups_1.csv" -NoTypeInformation -Force

Write-Host "Export completed. File saved as 'EnterpriseApps_UsersAndGroups_1.csv'."
