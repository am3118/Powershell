Connect-MgGraph
# Get all applications
$apps = Get-MgApplication -All

# EWS API and permission identifiers
$EWSAppId = "00000002-0000-0ff1-ce00-000000000000"
$EWS_AccessAsUser_All_Delegated = "EWS.AccessAsUser.All"
$EWS_AccessAsUser_All_App = "full_access_as_app"  # Application permission ID

# Filter apps with EWS permissions
$ewsApps = foreach ($app in $apps) {
    $reqAccess = $app.RequiredResourceAccess | Where-Object { 
        $_.ResourceAppId -eq $EWSAppId 
    }
    if ($reqAccess) {
        [PSCustomObject]@{
            DisplayName = $app.DisplayName
            AppId = $app.AppId
            ObjectId = $app.Id
            EWSResourceAccess = $reqAccess.ResourceAccess | ForEach-Object { "$($_.Type):$($_.Id)" }
        }
    }
}
$EWSApps | Export-Csv -Path "C:\temp\EWSApps.csv" -NoTypeInformation