# Requires Microsoft.Graph module
# Install-Module Microsoft.Graph -Scope CurrentUser

Connect-MgGraph -Scopes "Application.Read.All","Directory.Read.All"

# Enter the enterprise app display name
$appName = "PA - GlobalProtect (MKS Contractor Portal)"

# Find the service principal
$app = Get-MgServicePrincipal -Filter "displayName eq '$appName'" -All

if (-not $app) {
    throw "Enterprise application not found: $appName"
}

if ($app.Count -gt 1) {
    $app | Select-Object DisplayName, Id, AppId
    throw "Multiple apps matched. Narrow the appName or filter by AppId."
}

$app = $app | Select-Object -First 1

# Get all user/group assignments
$assignments = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $app.Id -All |
    Where-Object { $_.PrincipalType -in @("User","Group") } |
    Select-Object @{
        Name = "EnterpriseAppName"; Expression = { $app.DisplayName }
    }, @{
        Name = "EnterpriseAppObjectId"; Expression = { $app.Id }
    }, @{
        Name = "EnterpriseAppAppId"; Expression = { $app.AppId }
    }, PrincipalDisplayName, PrincipalId, PrincipalType, AppRoleId, ResourceDisplayName, ResourceId, CreatedDateTime

$csvPath = "C:\Temp\PAContractors_Assignments.csv"
$assignments | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "Exported to $csvPath"