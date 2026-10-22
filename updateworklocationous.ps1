$workLocations = Search-Resources -XPath "/WorkLocation" -Unconstrained

foreach($workLocation in $workLocations) {
    
    $workLocation | select DisplayName, VA_EnabledOU, VA_DisabledOU
    <#
    if($workLocation.VA_EnabledOU -notlike '*CTD*') {
        $workLocation.VA_EnabledOU = "OU=Users,OU=MKS,DC=mksinternal,DC=com"
        
        $workLocation.VA_DisabledOU = "OU=Disabled Users,OU=Enterprise,DC=mksinternal,DC=com"
        
        Save-Resource $workLocation
    }
    #>
}