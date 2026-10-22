<#
.SYNOPSIS
   This script finds disabled AD user accounts with an EmployeeID attribute value that have not been modified in the last 30 days, deletes them, sets the "deprovision" value for the corresponding MIM resources, and sends an email report.
.DESCRIPTION
   The script searches for disabled user accounts in Active Directory with an EmployeeID attribute value. It then checks if the userAccountControl attribute has not been modified in the last 30 days. If the condition is met, the script deletes the account, sets the "deprovision" value for the corresponding MIM resources, and sends an email report with summary and any errors.
#>

Import-Module ActiveDirectory
Import-Module LithnetRMA

$ErrorActionPreference = "Stop"
$dayCutoff = 30
$cutoffDate = (Get-Date).AddDays(-$dayCutoff)
# Logging configuration
$LogDirectory = "C:\Scripts\OffboardedUserCleanup\Logs"
Start-Transcript (Join-Path $LogDirectory "Transcript_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt")
$DetailedLogPath = Join-Path $LogDirectory "DetailedLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$SummaryLogPath = Join-Path $LogDirectory "SummaryLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$ErrorLogPath = Join-Path $LogDirectory "ErrorLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

if (-not (Test-Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory -Force
}

# Hashtable containing domain names and preferred domain controllers
$domainsAndPreferredDCs = @{
    'mksinternal.com' = 'MKSPLAI-DC01.mksinternal.com'
}

# Function to get a reachable domain controller for a domain
function Get-ReachableDomainController {
    param (
        $DomainName
    )
    try {
        $domainController = Get-ADDomainController -Identity $domainsAndPreferredDCs[$DomainName]
    } catch {
        Write-ErrorLog "Preferred domain controller $($domainsAndPreferredDCs[$DomainName]) not reachable for $DomainName. Discovering an available domain controller."
        $domainController = Get-ADDomainController -Discover -DomainName $DomainName
    }
    return $domainController
}

# Function to write to detailed log
function Write-DetailedLog {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Message
    )

    Add-Content -Path $DetailedLogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
}

# Function to write to summary log
function Write-SummaryLog {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Message
    )

    Add-Content -Path $SummaryLogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
}

# Function to write to error log
function Write-ErrorLog {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Message
    )

    Add-Content -Path $ErrorLogPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
}

function Get-DisabledUsersWithEmployeeID {
    [CmdletBinding()]
    param (
        $DomainController
    )

    Get-ADUser -Filter {Enabled -eq $false -and EmployeeID -like '*'} -Properties EmployeeID, userAccountControl, whenChanged -Server $DomainController
}

function Get-UserAccountControlLastModified {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $User,
        $DomainController
    )

    $metadata = Get-ADReplicationAttributeMetadata -Object $User -Attribute userAccountControl -Server $DomainController
    return $metadata.LastOriginatingChangeTime
}

function Set-MIMDeprovision {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $EmployeeID
    )

    $query = New-MVQuery -Attribute employeeID -Operator Equals -Value $EmployeeID
    $mvEmployee = Get-MVObject -Queries $query

    if ($null -ne $mvEmployee) {
        $resource = Get-Resource -AttributeName EmployeeID -AttributeValue $EmployeeID -ObjectType Person
        #$resource.adDistinguishedName = 'deprovision'
        #Save-Resource $resource
        Write-DetailedLog "MIM resource for EmployeeID '$EmployeeID' has been set to 'deprovision'."
    } else {
        Write-ErrorLog "MIM resource not found for EmployeeID '$EmployeeID'."
    }
}

function Send-EmailReport {
    param (
        $SummaryFilePath,
        $ErrorFilePath
    )

    $emailParams = @{
        From       = "offboarding@mksinst.com"
        To         = "greg.reed@mksinst.com"
        Subject    = "AD Cleanup Report"
        Body       = "Please find attached the summary and error logs for the AD cleanup process."
        Attachments = @($SummaryFilePath)
        SmtpServer = "mkssmtprelay.mksinternal.com"
    }

    if (Test-Path $ErrorFilePath) {
        $emailParams.Attachments += $ErrorFilePath
    }

    Send-MailMessage @emailParams
}

<#
# Update the hashtable with a reachable domain controller for each domain
foreach ($domainName in $domainsAndPreferredDCs.Keys) {
    $domainsAndPreferredDCs[$domainName] = (Get-ReachableDomainController -DomainName $domainName).HostName
}
#>

try {
    $deletedUsersCount = 0
    $errorsCount = 0

    foreach ($domain in $domainsAndPreferredDCs.Keys) {
        $domainController = $domainsAndPreferredDCs[$domain]
        $disabledUsers = Get-DisabledUsersWithEmployeeID -DomainController $domainController | Where-Object {$_.WhenChanged -le $cutoffDate -and $_.samaccountname -notlike 'Biju_Damodaran'}

        foreach ($user in $disabledUsers) {
            $lastModified = Get-UserAccountControlLastModified -User $user -DomainController $domainController

            if (((Get-Date) - $lastModified).Days -ge $dayCutoff) {
                try {
                    #Remove-ADObject -recursive -Identity $user.DistinguishedName -Confirm:$false -Server $domainController -Verbose
                    Write-DetailedLog "Deleted user '$($user.SamAccountName)' from domain '$domain'."
                    $deletedUsersCount++

                    #Set-MIMDeprovision -EmployeeID $user.EmployeeID
                } catch {
                    $errorMessage = "Error deleting user '$($user.SamAccountName)' from domain '$domain': $_"
                    Write-ErrorLog $errorMessage
                    Write-DetailedLog $errorMessage
                    $errorsCount++
                }
            }
        }
    }

    Write-SummaryLog "Deleted users count: $deletedUsersCount"
    Write-SummaryLog "Errors count: $errorsCount"

    Send-EmailReport -SummaryFilePath $SummaryLogPath -ErrorFilePath $ErrorLogPath
} catch {
    Write-ErrorLog "Unexpected error: $_"
}
