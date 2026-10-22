Connect-ExchangeOnline

$forwarding = Get-EXOMailbox -ResultSize Unlimited `
    -Filter 'ForwardingSmtpAddress -ne $null -or ForwardingAddress -ne $null' `
    -Properties ForwardingAddress, ForwardingSmtpAddress, DeliverToMailboxAndForward |
    Select-Object DisplayName, PrimarySmtpAddress,
        ForwardingAddress, ForwardingSmtpAddress, DeliverToMailboxAndForward

$forwarding | Format-Table -AutoSize

# Optional: Export results
$forwarding | Export-Csv C:\temp\MailboxForwarding.csv -NoTypeInformation