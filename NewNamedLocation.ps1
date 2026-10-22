Import-Csv 'c:\temp\NamedLocations.csv' | ForEach-Object {
    $ipList = $_.IpRanges -split ','
    $ipRangesList = [System.Collections.Generic.List[Microsoft.Open.MSGraph.Model.IpRange]]::new()
    foreach ($ip in $ipList) {
        $ipRange = New-Object Microsoft.Open.MSGraph.Model.IpRange
        $ipRange.cidrAddress = $ip.Trim()
        $ipRangesList.Add($ipRange)
    }
    $params = @{
        "@odata.type" = "#microsoft.graph.ipNamedLocation"
        DisplayName = $_.DisplayName
        IsTrusted = [bool]$_.IsTrusted
        IpRanges = $ipRangesList
    }
    New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params
    Write-Host "Created: $($_.DisplayName)"
}
