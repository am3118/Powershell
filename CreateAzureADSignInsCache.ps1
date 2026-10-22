function ConvertTo-Object {

begin { $object = New-Object Object }

process {

$_.GetEnumerator() | ForEach-Object { Add-Member -inputObject $object -memberType NoteProperty -name $_.Name -value $_.Value }  

}

end { $object }

}

Connect-Graph -Scopes "Reports.Read.All", "AuditLog.Read.All", "Directory.Read.All"
$allSignIns = @()
Write-Host "Querying signins"
$signins = Invoke-GraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/auditLogs/signIns?`$filter=createdDateTime ge 2021-01-25"
$allSignIns += $signins.value

while (-not [string]::IsNullOrEmpty($signins.'@odata.nextLink'))
{
    Write-Host "." -NoNewline
    $signIns = Invoke-GraphRequest -Method GET -Uri $signins.'@odata.nextLink'
    $allSignIns += $signins.value
}

foreach($signIn in $allSignIns)
{
   
    $caResults = $signIn.appliedConditionalAccessPolicies | %{$_ | ConvertTo-Object}
    $reportObject = "" | Select appDisplayName, ipAddress, conditionalAccessStatus, userPrincipalName, AzureAdminMFAResult,createdDateTime 

    $azureAdminPolicy = $caResults | ?{$_.id -like '1f85b7a8-9588-479c-8ab4-2cac023ed5c0'}
    $reportObject.appDisplayName = $signIn["appDisplayName"]
    $reportObject.conditionalAccessStatus = $signIn["conditionalAccessStatus"]
    $reportObject.userPrincipalName = $signIn["userPrincipalName"]
    $reportObject.createdDateTime = $signIn["createdDateTime"]
    $reportObject.AzureAdminMFAResult = $azureAdminPolicy.Result
    $reportObject.ipAddress = $signIn["ipAddress"]
    $reportObject | export-csv AzureADSignIns.csv -Append -NoTypeInformation -Encoding UTF8
}
