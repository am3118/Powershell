#Requirement: sharepoint online get all subsites powershell
#Load SharePoint CSOM Assemblies
#Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
#Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
 
#Variables
$SiteURL = "https://mksinst.sharepoint.com/sites/HFMAdmin-EnterpriseFinanceFinancialManagementTeam"
 
Try {
    #Get Credentials to connect
    $Cred= Get-Credential
 
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
   
    #Get the web
    $Web = $Ctx.web
    $Ctx.Load($Web)
     
    #get all subsites in sharepoint online powershell
    $Ctx.Load($Web.Webs)
    $Ctx.executeQuery()
 
    #Loop through each subsite and get subsite URL
    ForEach ($Subweb in $web.Webs) 
    {
       Write-host $Subweb.url 
    } 
}
Catch {
    write-host -f Red "Error:" $_.Exception.Message
}


#Read more: https://www.sharepointdiary.com/2016/02/powershell-to-get-all-subsites-in-site-collection-sharepoint-online.html#ixzz8bjy8dm00