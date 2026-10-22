# Connect to Exchange Online
Connect-ExchangeOnline

# Get all mailboxes
$mailboxes = Get-Mailbox -ResultSize Unlimited

# Create an array to store the results
$results = @()

foreach ($mailbox in $mailboxes) {
    $rules = Get-InboxRule -Mailbox $mailbox.UserPrincipalName

    $forwardingRules = $rules | Where-Object {$_.ForwardTo -or $_.ForwardAsAttachmentTo -or $_.RedirectTo}

    foreach ($rule in $forwardingRules) {
        $results += [PSCustomObject]@{
            Mailbox = $mailbox.UserPrincipalName
            RuleName = $rule.Name
            RuleDescription = $rule.Description
            ForwardTo = $rule.ForwardTo -join '; '
            ForwardAsAttachmentTo = $rule.ForwardAsAttachmentTo -join '; '
            RedirectTo = $rule.RedirectTo -join '; '
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "C:\temp\MKSAutoforwardRules.csv" -NoTypeInformation
