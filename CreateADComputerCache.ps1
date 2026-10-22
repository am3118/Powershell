$servers = @("mksplai-adcdc01.mksinternal.com","uspla-net02.newport.com","ESIPLAI-DC01.esi.com","DC19-04.coldswitch.local")
$fileDate = get-date -Format "yyyy-MM-dd"
$outFile = "C:\OneDriveMounts\EUCDataCollection\DailyReportFiles\ADComputers\ADComputers_$fileDate`.csv"

$adComputers = @()

foreach($server in $servers)
{
Write-Host "Loading Computers from $server"
$domain = $server.Split('.')[1]
$thisServersComputers = Get-ADComputer -filter * -Server $server -Properties DistinguishedName,Enabled,sAMAccountName,IPv4Address,Name,operatingSystemVersion,Description,LastLogonDate,OperatingSystem,pwdLastSet,ObjectGUID,dnshostname | Select DistinguishedName,Enabled,sAMAccountName,IPv4Address,Name,operatingSystemVersion,Description,LastLogonDate,OperatingSystem,pwdLastSet,@{Name=“Domain”;Expression={$domain}},ObjectGUID,dnshostname
$adComputers += $thisServersComputers
}

$adComputers | Select DistinguishedName,Enabled,sAMAccountName,IPv4Address,Name,operatingSystemVersion,Description,ObjectGUID,OperatingSystem,@{n='Parent';e={$_.distinguishedname -replace '^.+?,(CN|OU.+)','$1'}},LastLogonDate,@{Name=“pwdLastSet”;Expression={[datetime]::FromFileTime($_.pwdLastSet)}},domain,dnshostname| Export-CSV  $outFile -NoTypeInformation -Encoding:UTF8
