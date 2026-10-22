$OutputFile = "Office365relay-MessageStats.csv" 
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
    $CurrMessages = Get-MessageTrace -SenderAddress office365relay@mksinst.onmicrosoft.com -PageSize 5000 -Page $Page | Select RecipientAddress,Subject
    $Page++ 
    $Messages += $CurrMessages 
} 
until ($CurrMessages -eq $null) 
 
Remove-PSSession $session 
 
Write-Host "Crunching Results..." 
 
$Messages | export-csv $OutputFile 
 
Write-Host "Results saved to $OutputFile"