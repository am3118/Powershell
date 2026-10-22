$mailboxes = Get-Mailbox -ResultSize Unlimited
$domains = Get-AcceptedDomain

foreach ($mailbox in $mailboxes) {
  $forwardingSMTPAddress = $mailbox.forwardingsmtpaddress
  if ($forwardingSMTPAddress) {
    $email = ($forwardingSMTPAddress -split "SMTP:")[1]
    $domain = ($email -split "@")[1]
    if ($domains.DomainName -notcontains $domain) {
      Write-Host "$($mailbox.displayname) - $($mailbox.primarysmtpaddress) forwards to $email" -ForegroundColor Yellow
      $mailbox | Select-Object DisplayName,PrimarySmtpAddress,@{Name="ExternalRecipient";Expression={$email}} | Export-Csv C:\temp\MSDExternalmailForwards.csv -NoTypeInformation -Append
    }
  }
}