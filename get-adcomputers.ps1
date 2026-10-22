# Specify the OU to search
$OU = "DC=newport,DC=com"

# Get all computers in the specified OU
$Computers = Get-ADComputer -Filter * -SearchBase $OU -Properties LastLogonDate,distinguishedName -Server 'NPTANDI-DC01.newport.com'

# Sort the computers by LastLogonDate and display the results
$Computers | Sort-Object -Property LastLogonDate,distinguishedName | Select-Object Name, LastLogonDate,distinguishedName | Export-Csv c:\temp\NewportADComputers.csv -NoTypeInformation