Connect-SPOService -url https://mksinst.sharepoint.com

$sites = Get-SPOSite
foreach ($site in $sites) { 
      $subsites = Get-SPOSite -Identity $site.Url -Limit All
      foreach ($subsite in $subsites) {
            Write-Host "Processing site $($subsite.Url)"
            $folders = Get-SPOFolder -SiteRelativeUrl $subsite.ServerRelativeUrl -Recursive
            foreach ($folder in $folders) {
                  Write-Host "Folder: $($folder.ServerRelativeUrl)"
                  …………
            }
      }
}