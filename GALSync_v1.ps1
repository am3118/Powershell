Param (
    $Global:LastNameLetters = (65..90|foreach-object{[char]$_})[0..26]
)

#region Variables

#Primary Tenant Information
$Global:PrimaryTenantID = "34fc6b5f-c773-4cad-ae20-f226c36b7e65" # The Directory (tenant) ID from the Registered Application in Azure AD in the Primary tenant
$Global:PrimaryTenantSPNAppID = "1bdac516-18ff-401f-8bda-1660d7fbc431" # The Application (client) ID from the Registered Application in the Primary tenant
$Global:PrimaryTenantCertificate = "0F54679CA78F3B1147BA8C3E89480F975BEDD632" # The thumbprint of the authentication certificate generated for the Primary tenant
$Global:PrimaryTenantName = "mksinst.onmicrosoft.com" # The onmicrosoft.com domain of the primary tenant
$Global:PrimaryGuestGroupId = "537034a4-1eeb-4f7d-9d90-80b802f9e9a0" # The ObjectID of the group to add guests to in the Primary tenant
$Global:PrimaryToSecondaryGuestScopeGroup = "cae0ee31-029f-4701-8021-9def6ca54363" # The ObjectID of the group in the Primary tenant used to scope Guest synchronization to the secondary tenant. 
$Global:PrimaryInviteRedirectURL = "https://mksinst.sharepoint.com/" # The Url to redirect guests to after they accept the invite

#Secondary Tenant Information
$Global:SecondaryTenantID = "f2f02474-b6da-425b-999a-1263e18cfc3d" # The Directory (tenant) ID from the Registered Application in Azure AD in the Secondary tenant
$Global:SecondaryTenantSPNAppID = "620ee88c-4889-4efb-b558-130327587739" # The Application (client) ID from the Registered Application in the Secondary tenant
$Global:SecondaryTenantCertificate = "FEFA2F5894991ECCB56838EFC9EDA4123452187E" # The thumbprint of the authentication certificate generated for the Secondary
$Global:SecondaryTenantName = "atotechcloud.onmicrosoft.com" # The onmicrosoft.com domain of the Secondary tenant
$Global:SecondaryCompanyName = "Atotech" # The value to hardcode in the "Company" field for guests in the Primary Tenant
$Global:SecondaryInviteRedirectURL = "https://mksinst.sharepoint.com/" # The Url to redirect guests to after they accept the invite

#Script Variables
$Global:LogfileDate = get-date -Format "MM-dd-yyyy_HH-mm-ss" 
$Global:WorkingDirectory = "C:\Scripts\Identity\AtotechGALSync"
$Global:AzureADExtensionAttributeSuffix = "GALSyncGUID" # no need to change
$Global:LogDirectory = "$($Global:WorkingDirectory)\Logs4"
$Global:LogsToKeep = 7
$Global:TranscriptDirectory = "$($Global:WorkingDirectory)\Logs\Transcripts"
$Global:StatsFile = "$($Global:WorkingDirectory)\stats4.csv"

#Stats Variables
$Global:PrimaryTenantInvitedGuests = 0
$Global:PrimaryTenantDeletedGuests = 0
$Global:PrimaryUpdatedGuests = 0
$Global:SecondaryTenantInvitedGuests = 0
$Global:SecondaryTenantDeletedGuests = 0
$Global:SecondaryTenantUpdatedGuests = 0
$Global:SecondaryTenantCreatedContacts = 0
$Global:SecondaryTenantUpdatedContacts = 0
$Global:SecondaryTenantDeletedContacts = 0

#endregion Variables

#region Functions

function Write-Log
{
    param(
        $Message,
        $Category
    )
    $date = get-date -Format "MM-dd-yyyy HH:mm:ss"
    Write-Host "$date	$Category	 $Message"
    "$date	$Category	$($Message)" | Add-Content "$($Global:LogDirectory)\GALSync_$($Global:LogfileDate)`.log"
}

function Remove-OldLogs
{
    $logFiles = Get-ChildItem -Path $Global:LogDirectory *.log | Sort-Object -Property LastWriteTime -Descending
    if($logFiles.Count -ge $Global:LogsToKeep)
    {
        $logFiles[$Global:LogsToKeep..($logFiles.count -1)] | Remove-Item -Force -ErrorAction SilentlyContinue
    }

    $logFiles = Get-ChildItem -Path $Global:TranscriptDirectory *.txt | Sort-Object -Property LastWriteTime -Descending
    if($logFiles.Count -ge $Global:LogsToKeep)
    {
        $logFiles[$Global:LogsToKeep..($logFiles.count -1)] | Remove-Item -Force  -ErrorAction SilentlyContinue
    }
}

function Write-StatsFile
{
    $stats = [PSCustomObject]@{
        DateTime     = $Global:LogfileDate
        PrimaryTenantMailboxCount = $primaryMailboxes.count
        PrimaryTenantGuestcount = $existingPrimaryGuests.count
        PrimaryTenantInvitedGuest = $Global:PrimaryTenantInvitedGuests
        PrimaryTenantDeletedGuests = $Global:PrimaryTenantDeletedGuests
        PrimaryUpdatedGuests = $Global:PrimaryUpdatedGuests
        SecondaryTenantInvitedGuests = $Global:SecondaryTenantInvitedGuests
        SecondaryTenantDeletedGuests = $Global:SecondaryTenantDeletedGuests
        SecondaryTenantUpdatedGuests = $Global:SecondaryTenantUpdatedGuests
        SecondaryTenantCreatedContacts = $Global:SecondaryTenantCreatedContacts
        SecondaryTenantUpdatedContacts = $Global:SecondaryTenantUpdatedContacts
        SecondaryTenantDeletedContacts = $Global:SecondaryTenantDeletedContacts
        ErrorCount = $Error.count
    }

    $stats | export-csv $Global:StatsFile -NoTypeInformation -Append
}

function Update-GuestObject
{
[CmdletBinding()]
    [OutputType([psobject])]
    param (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [object]
        $SourceObject,
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 1)]
        $Guest,
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 2)]
        [string]
        $Tenant
    )
    $UpdateArguments = @{
        ObjectId = $Guest.ObjectId
    }

    if($tenant -like 'primary')
    {
        $displayName = "$($sourceobject.DisplayName) (MSD)"
        if(($guest | Select-Object -ExpandProperty extensionproperty)["$($Global:AzureADExtensionAttributeSuffix)"] -notlike $sourceobject.ExternalDirectoryObjectId) 
        {
            Set-AzureADUserExtension -ExtensionName $Global:extensionProperty -ExtensionValue $SourceObject.ExternalDirectoryObjectId -ObjectId $guest.ObjectId
        }
    } else {
        $displayName = "$($sourceobject.DisplayName) (MKS)"
    }

    if($guest.city -notlike $sourceobject.city) {$UpdateArguments.Add('city',$SourceObject.City)}
    if($guest.PhysicalDeliveryOfficeName -notlike $sourceobject.Office) {$UpdateArguments.Add('PhysicalDeliveryOfficeName',$SourceObject.Office)}
    if($guest.Country -notlike $sourceobject.CountryOrRegion) {$UpdateArguments.Add('Country',$SourceObject.CountryOrRegion)}
    if($guest.DisplayName -notlike $displayName) {$UpdateArguments.Add('DisplayName',$displayName)}
    if($guest.GivenName -notlike $sourceobject.FirstName) {$UpdateArguments.Add('GivenName',$SourceObject.FirstName)}
    if($guest.Surname -notlike $sourceobject.LastName) {$UpdateArguments.Add('Surname',$SourceObject.LastName)}
    if($guest.StreetAddress -notlike $sourceobject.StreetAddress) {$UpdateArguments.Add('StreetAddress',$SourceObject.StreetAddress)}
    if($guest.PostalCode -notlike $sourceobject.PostalCode) {$UpdateArguments.Add('PostalCode',$SourceObject.PostalCode)}
    if($guest.TelephoneNumber -notlike $sourceobject.Phone) {$UpdateArguments.Add('TelephoneNumber',$SourceObject.Phone)}
    if($guest.JobTitle -notlike $sourceobject.Title) {$UpdateArguments.Add('JobTitle',$SourceObject.Title)}
    if($guest.Department -notlike $sourceobject.Department) {$UpdateArguments.Add('Department',$SourceObject.Department)}
    if($guest.State -notlike $sourceobject.StateOrProvince) {$UpdateArguments.Add('State',$SourceObject.StateOrProvince)}
    if($guest.UserType -notlike 'Member') {$UpdateArguments.Add('UserType',"Member")}

    if($UpdateArguments.Keys.count -gt 1)
    {
        if($tenant -like 'primary')
        {
            $Global:PrimaryUpdatedGuests += 1
        }
        if($tenant -like 'secondary')
        {
            $Global:SecondaryTenantUpdatedGuests += 1
        }

        Write-Log -Category Info -Message "Updating $($UpdateArguments.Keys.count - 1) properties on $($Guest.UserPrincipalName)"
        Set-AzureADUser @UpdateArguments
    }
}

function Update-ContactObject
{
[CmdletBinding()]
    [OutputType([psobject])]
    param (
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 0)]
        [object]
        $SourceObject,
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true,
                   Position = 1)]
        $Contact
    )

        $UpdateArguments = @{
        Identity = $Contact.WindowsEmailAddress
    }

    
    $displayName = "$($sourceobject.DisplayName) (MKS)"

    if($Contact.city -notlike $sourceobject.city) {$UpdateArguments.Add('city',$SourceObject.City)}
    if($Contact.Office -notlike $sourceobject.Office) {$UpdateArguments.Add('Office',$SourceObject.Office)}
    if($Contact.CountryOrRegion -notlike $sourceobject.CountryOrRegion) {$UpdateArguments.Add('CountryOrRegion',$SourceObject.CountryOrRegion)}
    if($Contact.DisplayName -notlike $displayName) {$UpdateArguments.Add('DisplayName',$displayName)}
    if($Contact.FirstName -notlike $sourceobject.FirstName) {$UpdateArguments.Add('FirstName',$SourceObject.FirstName)}
    if($Contact.LastName -notlike $sourceobject.LastName) {$UpdateArguments.Add('LastName',$SourceObject.LastName)}
    if($Contact.StreetAddress -notlike $sourceobject.StreetAddress) {$UpdateArguments.Add('StreetAddress',$SourceObject.StreetAddress)}
    if($Contact.PostalCode -notlike $sourceobject.PostalCode) {$UpdateArguments.Add('PostalCode',$SourceObject.PostalCode)}
    if($Contact.Phone -notlike $sourceobject.Phone) {$UpdateArguments.Add('Phone',$SourceObject.Phone)}
    if($Contact.Title -notlike $sourceobject.Title) {$UpdateArguments.Add('Title',$SourceObject.Title)}
    if($Contact.Department -notlike $sourceobject.Department) {$UpdateArguments.Add('Department',$SourceObject.Department)}
    if($Contact.StateOrProvince -notlike $sourceobject.StateOrProvince) {$UpdateArguments.Add('StateOrProvince',$SourceObject.StateOrProvince)}
    if($Contact.WebPage -notlike $sourceobject.ExternalDirectoryObjectId) {$UpdateArguments.Add('WebPage',$SourceObject.ExternalDirectoryObjectId)}
    
    if($UpdateArguments.Keys.count -gt 1)
    {
        Write-Log -Category Info -Message "Updating $($UpdateArguments.Keys.count - 1) properties on $($Contact.WindowsEmailAddress)"
        Set-SecondaryContact @UpdateArguments
        $Global:SecondaryTenantUpdatedContacts += 1
    }
}

#endregion Functions

#region MainScript

if(-not (test-path $Global:LogDirectory -ErrorAction SilentlyContinue)) {mkdir $Global:LogDirectory -ErrorAction SilentlyContinue}
if(-not (test-path $Global:TranscriptDirectory -ErrorAction SilentlyContinue)) {mkdir $Global:TranscriptDirectory -ErrorAction SilentlyContinue}

Start-Transcript "$($Global:TranscriptDirectory)\GALSync_$($Global:LogfileDate).txt"

Write-Log -Category Info -Message "Connecting to Exchange Online"
Connect-ExchangeOnline -CertificateThumbprint $Global:PrimaryTenantCertificate -AppId $Global:PrimaryTenantSPNAppID -ShowBanner:$false -Organization $Global:PrimaryTenantName -Prefix Primary 
Connect-ExchangeOnline -CertificateThumbprint $Global:SecondaryTenantCertificate -AppId $Global:SecondaryTenantSPNAppID -ShowBanner:$false -Organization $Global:SecondaryTenantName -Prefix Secondary

Write-Log -Category Info -Message "Connecting to Azure AD"
Connect-AzureAD -TenantId $Global:PrimaryTenantID -ApplicationId $Global:PrimaryTenantSPNAppID -CertificateThumbprint $Global:PrimaryTenantCertificate | Out-Null

Write-Log -Category Info -Message "Get Secondary Tenant Exchange Recipients"
$secondaryContacts = Get-SecondaryContact -resultsize unlimited
$secondaryUsers = Get-SecondaryUser -ResultSize unlimited | Where-Object {$_.RecipientType -like 'UserMailbox' -and @('DiscoveryMailbox','sharedmailbox') -notcontains $_.RecipientTypeDetails -and $_.DisplayName -notlike 'Hot Desk*' -and (-not $_.AccountDisabled)}

Write-Log -Category Info -Message "Get Primary Tenant Exchange Recipients"
$primaryMailboxes = Get-PrimaryMailbox -resultsize unlimited
$primaryUsers = Get-PrimaryUser -ResultSize unlimited | Where-Object {$_.RecipientType -like 'UserMailbox' -and @('DiscoveryMailbox','sharedmailbox') -notcontains $_.RecipientTypeDetails -and $_.DisplayName -notlike 'Hot Desk*' -and (-not $_.AccountDisabled)}

Write-Log -Category Info -Message "Get Primary Tenant Guest Users"
$existingPrimaryGuests = Get-AzureADUser -All:$true |Where-Object {$_.UserPrincipalName -like '*#EXT#*'} #get-msoluser -UnlicensedUsersOnly -DomainName mksinst.onmicrosoft.com -all:$true | ?{$_.UserPrincipalName -like "*photoncontrol.com#EXT#@MKSINST.onmicrosoft.com" -or $_.UserPrincipalName -like "*micronor.com#EXT#@MKSINST.onmicrosoft.com" -or $_.UserPrincipalName -like "*photoncontrolInc.onmicrosoft.com#EXT#@MKSINST.onmicrosoft.com" }

Write-Log -Category Info -Message "Getting Primary Tenant Guest Group memberships"
$groupMembers = Get-AzureADGroupMember -objectid $Global:PrimaryGuestGroupId -all:$true
#$primaryUsersInScope = Get-AzureADGroupMember -ObjectId $Global:PrimaryToSecondaryGuestScopeGroup -all:$true

Write-Log -Category Info -Message "Updating Guests for Secondary Users in Primary Tenant"
$Global:extensionProperty = (Get-AzureADApplication | Get-AzureADApplicationExtensionProperty | Where-Object {$_.Name -like "*$($Global:AzureADExtensionAttributeSuffix)"}).Name | Select-Object -First 1

$x = 1;

foreach($user in ($secondaryUsers | Where-Object {$Global:LastNameLetters -contains $_.LastName[0]}))
{
    if($x % 50 -eq 0){Write-Log -Category Info "Guests processed: $x"}

    $x++
    $existingUser = $null
     
    $existingUser = $existingPrimaryGuests | Where-Object {$_.ProxyAddresses -contains "SMTP:$($user.WindowsEmailAddress)" }

    if(-not $existingUser -and ($null -notlike $user.Department))
    {
        Write-Log -Category Info -Message "$($user.userprincipalname) does not exist. Creating a new Guest Invite."
        
        $newUser = New-AzureADMSInvitation -InvitedUserDisplayName $user.DisplayName -InvitedUserEmailAddress $user.WindowsEmailAddress -InviteRedirectURL $Global:SecondaryInviteRedirectURL -SendInvitationMessage $true
        $existinguser = Get-AzureADUser -ObjectID $newUser.InvitedUser.Id
        $Global:PrimaryTenantInvitedGuests += 1
        Set-AzureADUser -ObjectId $existingUser.ObjectId -ShowInAddressList:$true -CompanyName $Global:SecondaryCompanyName
        Update-GuestObject $user $existingUser "Primary"
        Set-AzureADUserExtension -ObjectId $existingUser.ObjectId -ExtensionValue $user.ExternalDirectoryObjectId -ExtensionName $Global:extensionProperty
        #>
    }
    else
    {
        Write-Log -Category Info -Message "$($user.userprincipalname) exists. Checking for updates"
        Set-AzureADUser -ObjectId $existingUser.ObjectId -ShowInAddressList:$true -CompanyName $Global:SecondaryCompanyName
        Update-GuestObject $user $existingUser "Primary"
    }
    
    if($groupMembers.ObjectId -notcontains $existingUser.ObjectId)
    {
        #Add-AzureADGroupMember -objectid $Global:PrimaryGuestGroupId -RefObjectId $existingUser.ObjectId
    }
}

<#
Write-Log -Category Info -Message "Updating Contacts for Primary Users in Secondary Tenant"
$x = 1;
foreach($user in ($primaryUsers | Where-Object {$Global:LastNameLetters -contains $_.LastName[0]}))
{
    if($x -le 1300){$x++;continue}
    if($x % 50 -eq 0){Write-Log -Category Info "Guests processed: $x"}

    $x++
    $contact = $secondaryContacts | Where-Object {($_.WindowsEmailAddress -like $user.WindowsEmailAddress) -or $_.WebPage -like $user.ExternalDirectoryObjectId}
     
    if($secondaryContacts.WindowsEmailAddress -notcontains $user.WindowsEmailAddress)
    {
        try {
        New-SecondaryMailContact -name "$($user.WindowsEmailAddress.split('@')[0])_galsync" -ExternalEmailAddress $user.WindowsEmailAddress 
        }
        catch
        {
        }
        $contact = get-Secondarycontact $user.WindowsEmailAddress
        Update-ContactObject $user $contact
        $Global:SecondaryTenantCreatedContacts += 1
    }
    else
    {
        Update-ContactObject $user $contact
    }
}


Write-Log -Category Info -Message "Removing Guests in the Primary tenant for Secondary users that no longer exist."
foreach ($PrimaryGuest in $existingPrimaryGuests)
{
    $guid = $primaryGuest.ExtensionProperty["$($Global:extensionProperty)"]
    if($secondaryMailboxes.ExternalDirectoryObjectId -notcontains $guid)
    {
        if($guid)
        {
            Write-Log -Category Info -Message "The Mailbox in the secondary tenant for $guid no longer exists. Removing the Guest from the Primary tenant."
            #Remove-AzureADUser -ObjectId $PrimaryGuest.ObjectID
        }
    }
    else
    {
    }
}
#>

Write-Log -Category Info -Message "Removing Contacts in the Secondary tenant for Primary users that no longer exist."
foreach ($secondaryContact in $secondaryContacts)
{
    if ($PrimaryUsers.ExternalDirectoryObjectId -notcontains $secondaryContact.WebPage)
    {
        Write-Log -Category Info -Message "$($secondaryContact.WebPage) Does not exist (Removing Contact)"
        #Remove-SecondaryMailContact $secondaryContact.WindowsEmailAddress -confirm:$false
        $Global:SecondaryTenantDeletedContacts += 1
    }
}

Write-Log -Category Info -Message "Switching Azure AD PowerShell to Secondary Tenant"
Disconnect-AzureAD | Out-Null
Connect-AzureAD -TenantId $Global:SecondaryTenantID -ApplicationId $Global:SecondaryTenantSPNAppID -CertificateThumbprint $Global:SecondaryTenantCertificate  | Out-Null
$Global:extensionProperty = (Get-AzureADApplication | Get-AzureADApplicationExtensionProperty | Where-Object {$_.Name -like "*$($Global:AzureADExtensionAttributeSuffix)"}).Name | Select-Object -First 1
Write-Log -Category Info -Message "Getting existing Secondary Tenant Guest Users"

$existingSecondaryGuests = Get-AzureADUser -All:$true |Where-Object {$_.UserPrincipalName -like '*#EXT#*'} #get-msoluser -UnlicensedUsersOnly -DomainName mksinst.onmicrosoft.com -all:$true | ?{$_.UserPrincipalName -like "*photoncontrol.com#EXT#@MKSINST.onmicrosoft.com" -or $_.UserPrincipalName -like "*micronor.com#EXT#@MKSINST.onmicrosoft.com" -or $_.UserPrincipalName -like "*photoncontrolInc.onmicrosoft.com#EXT#@MKSINST.onmicrosoft.com" }
Write-Log -Category Info -Message "Updating Guests in the Secondary tenant for Primary tenant users."

foreach($user in ($primaryUsers | Where-Object {$Global:LastNameLetters -contains $_.LastName[0]}))
{
    $existingUser = $existingSecondaryGuests | Where-Object {($_.ProxyAddresses -contains "SMTP:$($user.WindowsEmailAddress)") -or ($_.OtherMails -contains "$($User.WindowsEmailAddress)") }
    $scopedUser = $null
    $scopedUser = $primaryUsersInScope | Where-Object {$_.ObjectId -like $user.ExternalDirectoryObjectId}
    
    if($scopedUser)
    {
        if(-not $existingUser)
        {
            Write-Log -Category Info -Message "$($user.WindowsEmailAddress) does not exist, Inviting a new user."
            #add logic to delete contact
            $newUser = New-AzureADMSInvitation -InvitedUserDisplayName $user.DisplayName -InvitedUserEmailAddress $user.WindowsEmailAddress -InviteRedirectURL $Global:PrimaryInviteRedirectURL -SendInvitationMessage $false
            $Global:SecondaryTenantInvitedGuests += 1
            $existinguser = Get-AzureADUser -ObjectID $newUser.InvitedUser.Id
            start-sleep 2
            Set-AzureADUser -ObjectId $existingUser.ObjectId -ShowInAddressList:$true -CompanyName $existingUser.CompanyName
            Update-GuestObject $user $existinguser "Secondary"
        }
        else
        {
            Write-Log -Category Info -Message "Guest for $($user.userprincipalname) exists, checking for updates."
            Update-GuestObject $user $existinguser "Secondary"
            Set-AzureADUser -ObjectId $existingUser.ObjectId -ShowInAddressList:$true
        }
    }
}
<#
Write-Log -Category Info -Message "Removing Guests in the Secondary tenant for Primary users that no longer exist or are not in scope."
foreach ($SecondaryGuest in $existingSecondaryGuests)
{
    $guid = $SecondaryGuest.ExtensionProperty["$($Global:extensionProperty)"]

    $scopedUser = $null

    $scopedUser = $primaryUsersInScope | Where-Object {$_.ObjectId -like $guid}

    if(-not $scopedUser)
    {
        Write-Log -Category Info -Message "The Mailbox in the Primary tenant for $guid no longer exists or is not in scope for sync. Removing the Guest from the Primary tenant."
        #Remove-AzureADUser -ObjectId $SecondaryGuest.ObjectID
        $Global:SecondaryTenantDeletedGuests += 1
    }
    else
    {
    }
}
#>
Disconnect-AzureAD | Out-Null
Disconnect-ExchangeOnline -Confirm:$false
Write-StatsFile
#endregion MainScript

Stop-Transcript
start-sleep 5
Remove-OldLogs