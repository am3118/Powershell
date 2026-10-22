$Group = "Tessian-exception@MKSINST.onmicrosoft.com"
$Contacts = Import-Csv "C:\Temp\tessian-exception.csv"

# Confirm that you have the correct group
Get-DistributionGroup -Identity $Group |
    Format-List DisplayName, PrimarySmtpAddress, RecipientTypeDetails, IsDirSynced

$Results = foreach ($Contact in $Contacts) {
    $Email = $Contact.EmailAddress.Trim()

    try {
        # Resolve the existing mail contact before adding it
        $Recipient = Get-MailContact -Identity $Email -ErrorAction Stop

        Add-DistributionGroupMember `
            -Identity $Group `
            -Member $Recipient.Identity `
            -ErrorAction Stop

        [pscustomobject]@{
            EmailAddress = $Email
            Status       = "Added"
            Details      = ""
        }
    }
    catch {
        [pscustomobject]@{
            EmailAddress = $Email
            Status       = "Not added"
            Details      = $_.Exception.Message
        }
    }
}

$Results | Format-Table -AutoSize
$Results | Export-Csv "C:\Temp\ContactImportResults.csv" -NoTypeInformation