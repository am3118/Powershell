#Install-Module Microsoft.Graph -Scope CurrentUser
#Connect-MgGraph -Scopes "Policy.Read.All" -NoWelcome -TenantId "34fc6b5f-c773-4cad-ae20-f226c36b7e65"

$locations = Get-MgIdentityConditionalAccessNamedLocation

$result = foreach ($loc in $locations) {
    [pscustomobject]@{
        Id                         = $loc.Id
        DisplayName                = $loc.DisplayName
        IsTrusted                  = $loc.AdditionalProperties.isTrusted
        Type                       = if ($loc.AdditionalProperties.ipRanges) { "IP" } elseif ($loc.AdditionalProperties.countriesAndRegions) { "Country" } else { "Unknown" }
        IPRanges                   = ($loc.AdditionalProperties.ipRanges.cidrAddress -join ";")
        CountriesAndRegions        = ($loc.AdditionalProperties.countriesAndRegions -join ";")
        IncludeUnknownCountries     = $loc.AdditionalProperties.includeUnknownCountriesAndRegions
    }
}

$result | Export-Csv "C:\Temp\MKS-Entra-NamedLocations.csv" -NoTypeInformation -Encoding UTF8