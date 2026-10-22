

Connect-ExchangeOnline

$ruleName = "Block Outbound to gdxihai.cn"
$start    = "2026-10-08T15:57:20.0000000Z"
$end = "2026-10-08T16:24:59.0000000Z"

# Confirm the rule and inspect its current settings
$rule = Get-TransportRule -Identity $ruleName
$rule | Format-List Name,Guid,State,Mode,SetAuditSeverity,Description

# Retrieve all pages of historical rule hits
$hits = @(
    for ($page = 1; $page -le 1000; $page++) {
        $batch = @(
            Get-MailDetailTransportRuleReport `
                -TransportRule $ruleName `
                -EventType TransportRuleHits `
                -StartDate $start `
                -EndDate $end `
                -PageSize 5000 `
                -Page $page
        )

        $batch

        if ($batch.Count -lt 5000) {
            break
        }
    }
)

$hits | Format-List *

$hits | Export-Csv "C:\temp\gdxihaicnTransportRuleHits.csv" -NoTypeInformation