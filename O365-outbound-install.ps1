# Mail Flow Configuration for Office 365 -> run in PowerShell ISE (as Administrator)
# On macOS or Linux (not required on Windows), WSMan needs to be installed (restart PowerShell session afterwards):
# Install-Module -Name PSWSMan; Install-WSMan

Write-Host ""
Write-Host "Tessian Gateway -> Mail Flow Configuration -> Create with MFA"
Write-Host "-------------------------------------------------------------"
Write-Host ""

# Check installation mode
$installationMode = Read-Host -Prompt "Do you want to install [O]utbound, [J]ournal or [B]oth?"
$installOutbound = ($installationMode -eq 'O') -or ($installationMode -eq 'B')
$installJournal = ($installationMode -eq 'J') -or ($installationMode -eq 'B')

# Ask for confirmation
$toBeInstalled = @(if ($installOutbound) { 'Outbound' }) + @(if ($installJournal) { 'Journal' })
if ($toBeInstalled.count -le 0) {
    Write-Warning "Not installing Outbound nor Journal"
    return 2
}
$confirmation = Read-Host -Prompt "Are you sure you want to install $($toBeInstalled -join ' and ') [y/N]?"
if ($confirmation -ne 'Y') {
    Write-Warning "Installation cancelled"
    return 2
}

# Perform installation
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
if (-not (Get-Module "ExchangeOnlineManagement" -ErrorAction SilentlyContinue)) {
    if (-not (Get-PSRepository "PSGallery" -ErrorAction SilentlyContinue)) {
        Write-Host "-- Registering PSGallery --"
        Register-PSRepository -Default -InstallationPolicy Trusted # makes MS PSGallery available
    }
    Write-Host "-- Installing Office 365 connection module --"
    Install-Module -Name ExchangeOnlineManagement # installs module from MS PSGallery
}

try {
    Write-Host "-- Connecting to Office 365 --"
    Import-Module ExchangeOnlineManagement
    Connect-ExchangeOnline -ShowBanner:$false 
}
catch {
    Write-Error "Cannot connect to Office 365`r`n$_.Exception.Message"
    return 1
}
Write-Host "Office 365 session started."

# Define properties
$SmartHost_Outbound = "a0524ebc-outbound.mta.tessian-gw.com"
$SmartHost_Journal = "a0524ebc-journal.mta.tessian-gw.com"
$SenderIPRanges = "52.88.87.176", "35.81.186.128"
$ClientMailDomain = "mks.com"
$ClientJournalDomain = "cr-journal.mks.com"

# Define object identities
$Prefix = "Tessian"
$OutboundSendConnectorName = "$Prefix Outbound"
$JournalSendConnectorName = "$Prefix Journal"
$RelayReceiveConnectorName = "$Prefix Outbound Relay"
$OutboundRoutingGroupName = "$Prefix Outbound Routing Group"
$AlertsContactName = "$Prefix Alerts"
$JournalContactName = "$Prefix Journal"
$OutboundTransportRuleName = "$Prefix Outbound Routing"
$AlertTransportRuleName = "$Prefix Alert Routing"
$JournalRuleName = "$Prefix Journal"

# Define SMTP addresses
$OutboundRoutingGroupSmtp = "tessianoutboundrouting@$ClientMailDomain"
$AlertsContactSmtp = "tessian@$ClientMailDomain"
$JournalingContactSmtp = "journaling@$ClientJournalDomain"

if ($installOutbound) {
    #OutboundSendConnectorName Connector********************************
    Write-Host "-- creating $OutboundSendConnectorName Connector --"

    $outboundConnector = Get-OutboundConnector -Identity $OutboundSendConnectorName -ErrorAction SilentlyContinue
    if ($null -ne $outboundConnector) {
        #outbound connector exists - remove and add again
        Remove-OutboundConnector -Identity $OutboundSendConnectorName -Confirm:$false
    }

    New-OutboundConnector -Name $OutboundSendConnectorName -IsTransportRuleScope $true -ConnectorType OnPremises -SmartHosts $SmartHost_Outbound -Comment "Forward outbound messages to $SmartHost_Outbound" -UseMXRecord $false -CloudServicesMailEnabled $true -TlsSettings DomainValidation -TlsDomain ($Smarthost_outbound -replace '^[\w-]+\.', '*.')
    #OutboundSendConnectorName Connector********************************

    #RelayReceiveConnectorName Connector********************************
    Write-Host "-- creating $RelayReceiveConnectorName Connector --"

    $relayConnector = Get-InboundConnector -Identity $RelayReceiveConnectorName -ErrorAction SilentlyContinue
    if ($null -ne $relayConnector) {
        Remove-InboundConnector -Identity $RelayReceiveConnectorName -Confirm:$false
    }

    New-InboundConnector -Name $RelayReceiveConnectorName -SenderIPAddresses $SenderIPRanges -RestrictDomainstoIPAddresses $true -SenderDomains * -ConnectorType OnPremises -CloudServicesMailEnabled $true -TreatMessagesAsInternal $false -RequireTLS $true
    #RelayReceiveConnectorName Connector********************************

    #OutboundRoutingGroupName Security Group********************************
    Write-Host "-- creating $OutboundRoutingGroupName Security Group --"

    #only create if doesn't already exist
    $outboundRoutingGroup = Get-DistributionGroup -Identity $OutboundRoutingGroupName -ErrorAction SilentlyContinue
    if ($null -eq $outboundRoutingGroup) {
        New-DistributionGroup -Type Security -Name $OutboundRoutingGroupName -IgnoreNamingPolicy -Alias tessianoutboundrouting -Notes "Users to route through $Prefix Outbound Gateway" -PrimarySmtpAddress $OutboundRoutingGroupSmtp
        Set-DistributionGroup $OutboundRoutingGroupName -HiddenFromAddressListsEnabled:$true
    }
    #OutboundRoutingGroupName Security Group********************************

    #AlertsContactName********************************
    Write-Host "-- creating $AlertsContactName Mail Contact --"

    $alertsContact = Get-MailContact -Identity $AlertsContactName -ErrorAction SilentlyContinue
    if ($null -ne $alertsContact) {
        Remove-MailContact -Identity $AlertsContactName -Confirm:$false
    }

    New-MailContact -Name $AlertsContactName -ExternalEmailAddress $AlertsContactSmtp
    #AlertsContactName********************************

    #OutboundTransportRuleName********************************
    Write-Host "-- creating $OutboundTransportRuleName Transport Rule --"

    $outboundTransportRule = Get-TransportRule -Identity $OutboundTransportRuleName -ErrorAction SilentlyContinue
    if ($null -ne $outboundTransportRule) {
        Remove-TransportRule -Identity $OutboundTransportRuleName -Confirm:$false
    }

    New-TransportRule `
        -Name $OutboundTransportRuleName `
        -FromMemberOf $OutboundRoutingGroupName `
        -SetHeaderName "X-CheckRecipientRouted" `
        -SetHeaderValue "true" `
        -Priority 1 `
        -RuleErrorAction Ignore `
        -StopRuleProcessing $true `
        -ExceptIfHeaderContainsMessageHeader "X-CheckRecipientRouted" `
        -ExceptIfHeaderContainsWords true, routed `
        -ExceptIfHeaderMatchesMessageHeader "X-CheckRecipientChecked" `
        -ExceptIfHeaderMatchesPatterns "true" `
        -RouteMessageOutboundConnector $OutboundSendConnectorName `
        -SenderAddressLocation Envelope
    #OutboundTransportRuleName********************************

    #AlertTransportRuleName********************************
    Write-Host "-- creating $AlertTransportRuleName Transport Rule --"

    $alertTransportRule = Get-TransportRule -Identity $AlertTransportRuleName -ErrorAction SilentlyContinue
    if ($null -ne $alertTransportRule) {
        Remove-TransportRule -Identity $AlertTransportRuleName -Confirm:$false
    }
    
    New-TransportRule `
        -Name $AlertTransportRuleName `
        -FromMemberOf $OutboundRoutingGroupName `
        -SentTo $AlertsContactSmtp `
        -Priority 2 `
        -RuleErrorAction Ignore `
        -StopRuleProcessing $true `
        -RouteMessageOutboundConnector $OutboundSendConnectorName `
        -SenderAddressLocation Envelope
    #AlertTransportRuleName********************************
}

if ($installJournal) {
    #JournalSendConnectorName Connector********************************
    Write-Host "-- creating $JournalSendConnectorName Connector --"

    $outboundJournalConnector = Get-OutboundConnector -Identity $JournalSendConnectorName -ErrorAction SilentlyContinue
    if ($null -ne $outboundJournalConnector) {
        #outbound connector exists - remove and add again
        Remove-OutboundConnector -Identity $JournalSendConnectorName -Confirm:$false
    }

    New-OutboundConnector -Name $JournalSendConnectorName -IsTransportRuleScope $false -ConnectorType Partner -SmartHosts $SmartHost_Journal -RecipientDomains $ClientJournalDomain -Comment "Copy inbound messages to $SmartHost_Journal" -UseMXRecord $false -TlsSettings DomainValidation -TlsDomain ($SmartHost_Journal -replace '^[\w-]+\.', '*.')
    #JournalSendConnectorName Connector********************************

    #JournalContactName********************************
    Write-Host "-- creating $JournalContactName Mail Contact --"

    $journalContact = Get-MailContact -Identity $JournalContactName -ErrorAction SilentlyContinue
    if ($null -ne $journalContact) {
        Remove-MailContact -Identity $JournalContactName -Confirm:$false
    }

    New-MailContact -Name $JournalContactName -ExternalEmailAddress $JournalingContactSmtp
    #JournalContactName********************************

    #JournalRuleName********************************
    Write-Host "-- creating $JournalRuleName Transport Rule --"

    $journalRule = Get-JournalRule -Identity $JournalRuleName -ErrorAction SilentlyContinue
    if ($null -ne $journalRule) {
        Remove-JournalRule -Identity $JournalRuleName -Confirm:$false
    }

    New-JournalRule -Name $JournalRuleName -JournalEmailAddress $JournalingContactSmtp -Scope Global -Recipient $OutboundRoutingGroupSmtp -Enabled $true
    #JournalRuleName********************************
}

Write-Host ""
Write-Host "-- Configuration Complete --"
Write-Host ""

# Disconnect Office 365 session
Disconnect-ExchangeOnline -Confirm:$false 
 
