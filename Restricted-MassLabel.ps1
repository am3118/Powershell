Import-Module PurviewInformationProtection

$LabelId = "86fa3a00-6c72-4ca5-90d9-035c6217dad9"
$StagingFolder = "C:\10\TR Data Incident"

# These recipients receive the same encryption rights on every processed file.
$Permissions = New-CustomPermissions `
    -Users "Danielle.Massey@mksinst.com","Mandy.Atkinson@mksinst.com" `
    -Permissions CoOwner

$Results = Set-FileLabel `
    -Path $StagingFolder `
    -LabelId $LabelId `
    -CustomPermissions $Permissions `
    -PreserveFileDetails

$Results | Format-List *
