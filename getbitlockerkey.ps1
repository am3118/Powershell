param(
[Parameter(Mandatory)]
[string]$ComputerName
)
Try{$computer = Get-ADComputer $computername -ea stop}catch{write-host "$ComputerName - not found";exit}
$q = Get-ADObject -Filter 'objectClass -eq "msFVE-RecoveryInformation"' -SearchBase $computer.DistinguishedName -Properties whenCreated, msFVE-RecoveryPassword | `
  Sort whenCreated -Descending | Select whenCreated, msFVE-RecoveryPassword
If($q) {$q}
else{write-host "Confirm you are running with the appropriate rights" -foregroundcolor DarkGray}