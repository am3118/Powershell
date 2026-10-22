################################################################################################################################################################ 
# This script connects to Office 365 and retrieves detailed SMTP mail traffic statistics by user 
# Requires Office 365 Wave 15 
# 
# Office365Username - Mandatory - Administrator login ID for the tenant we are querying 
# Office365Password - Mandatory - Administrator login password for the tenant we are querying 
#  
# This script outputs the results to a CSV file called DetailedMessageStats.csv 
# 
# To run the script 
# 
# .\Get-DetailedMessageStats.ps1 -Office365Username admin@xxxxxx.onmicrosoft.com -Office365Password Password123  
# 
# 
# Author:                 Alan Byrne 
# Version:                 1.1
# Last Modified Date:     17/01/2013 
# Last Modified By:     Alan Byrne @alanmbyrne 
################################################################################################################################################################ 
 
#Accept input parameters 
Param( 
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)] 
    [string] $Office365Username, 
    [Parameter(Position=1, Mandatory=$false, ValueFromPipeline=$true)] 
    [string] $Office365Password 
) 
 
$OutputFile = "MessageTrack-export-Photon.csv" 
 
#Did they provide creds?  If not, ask them for it.
if (([string]::IsNullOrEmpty($Office365Username) -eq $false) -and ([string]::IsNullOrEmpty($Office365AdminPassword) -eq $false))
{
    $SecureOffice365AdminPassword = ConvertTo-SecureString -AsPlainText $Office365AdminPassword -Force     
     
    #Build credentials object 
    $Office365Credentials  = New-Object System.Management.Automation.PSCredential $Office365Username, $SecureOffice365AdminPassword 
}
else
{
    #Build credentials object 
    $Office365Credentials  = Get-Credential
}

#Create remote Powershell session 
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell –AllowRedirection         

#Import the session 
Import-PSSession $Session -AllowClobber | Out-Null
 
Write-Host "Collecting Recipients..." 
 
#Collect all recipients from Office 365 
$Recipients = Get-Recipient * | select PrimarySMTPAddress 

$MailTraffic = @{} 
foreach($Recipient in $Recipients) 
{ 
    $MailTraffic[$Recipient.PrimarySMTPAddress.ToLower()] = @{} 
} 
$Recipients = $null 
 
#Collect Message Tracking Logs (These are broken into "pages" in Office 365 so we need to collect them all with a loop) 
$Messages = $null 
$Page = 1 
do 
{ 
    Write-Host "Collecting Message Tracking - Page $Pagvce..." 
    $CurrMessages = Get-MessageTrace -SenderAddress smtprelay@photoncontrol.com -PageSize 5000 -Page $Page | Select RecipientAddress,Subject
    $Page++ 
    $Messages += $CurrMessages 
} 
until ($CurrMessages -eq $null) 
 
Remove-PSSession $session 
 
Write-Host "Crunching Results..." 
 
$Messages | export-csv $OutputFile 
 
Write-Host "Results saved to $OutputFile"