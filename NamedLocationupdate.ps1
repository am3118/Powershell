Connect-MgGraph
Import-Csv 'C:\temp\NamedLocations.csv' | ForEach-Object {
    $policy = Get-MgIdentityConditionalAccessNamedLocation | Where-Object DisplayName -eq $_.DisplayName
    if ($policy) {
        $ipRange = [Microsoft.Open.MSGraph.Model.IpRange]::new()
        $ipRange.cidrAddress = $_.IpRange
        Update-MgIdentityConditionalAccessNamedLocation -NamedLocationId $policy.Id -IpRanges @($ipRange)
        Write-Host "Updated: $($_.DisplayName)"
    }
}
