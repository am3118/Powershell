Connect-AzureAD
# Retrieve all service principals (enterprise applications)
$ServicePrincipals = Get-AzureADServicePrincipal -All $true | Where-Object { $_.DisplayName -like '*PA - GlobalProtect*' }

# Loop through each service principal and retrieve group assignments
$AppRoleAssignments = foreach ($ServicePrincipal in $ServicePrincipals) {
    Get-AzureADServiceAppRoleAssignment -ObjectId $ServicePrincipal.ObjectId | Where-Object {$_.PrincipalType -eq "Group"}
}

# Map group details and export data
$MappedGroups = foreach ($Assignment in $AppRoleAssignments) {
    $Group = Get-AzureADGroup -ObjectId $Assignment.PrincipalId
    [PSCustomObject]@{
        EnterpriseApplicationName = (Get-AzureADServicePrincipal -ObjectId $Assignment.ResourceId).DisplayName
        EnterpriseApplicationID = $Assignment.ResourceId
        GroupName = $Group.DisplayName
        GroupID = $Group.ObjectId
    }
}

# Export data to CSV file
$MappedGroups | Export-Csv -Path "c:\temp\PA-GlobalProtectAppsGroups.csv" -NoTypeInformation
