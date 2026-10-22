Get-EntraDirectoryRoleAssignment -All | 
    Select-Object @{Name='UPN';Expression={(Get-EntraUser -ObjectId $_.PrincipalId).UserPrincipalName}}, 
                  @{Name='RoleName';Expression={(Get-EntraDirectoryRoleDefinition -ObjectId $_.RoleDefinitionId).DisplayName}} | Export-Csv -Path 'C:\temp\Entraroles.csv' -NoTypeInformation