Connect-ExchangeOnline

Get-MailDetailTransportRuleReport `
    -TransportRule "Your transport rule name" `
    -StartDate (Get-Date).AddDays(-7) `
    -EndDate (Get-Date) `
    -PageSize 5000 |
    Select-Object Date, TransportRule, Subject,
                  SenderAddress, RecipientAddress,
                  Action, MessageId, MessageTraceId |
    Format-Table -AutoSize