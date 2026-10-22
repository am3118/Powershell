Get-ADGroup -Filter "Name -like '*DDPE*'" | Select-Object Name

(Get-ADGroupMember -Identity "Encryption_DDPE_CTD ").Count