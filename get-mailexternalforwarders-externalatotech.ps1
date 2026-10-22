# Connect to Exchange Online (make sure you have the necessary permissions)
Connect-ExchangeOnline

# Replace "example.com" with the specific domain suffix you're looking for
$domainSuffix = "external.atotech.com"

# Get mailboxes with forwarding enabled to the specified domain suffix
$forwardedMailboxes = Get-Mailbox -ResultSize Unlimited | Where-Object {
    $_.ForwardingSmtpAddress -like "*@$domainSuffix"
}

# Display the results
$forwardedMailboxes | Select-Object DisplayName, PrimarySmtpAddress, ForwardingSmtpAddress

# Optionally, export the results to a CSV file
$forwardedMailboxes | Select-Object DisplayName, PrimarySmtpAddress, ForwardingSmtpAddress | Export-Csv -Path "externalAtotechForwardedMailboxes.csv" -NoTypeInformation
