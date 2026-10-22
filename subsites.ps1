$sites = Get-SPOSite -Filter { URL -like "https://mksinst.sharepoint.com/sites/HFMAdmin-EnterpriseFinanceFinancialManagementTeam" }
foreach ($site in $sites) { 
      Get-ChildItem
      
}

