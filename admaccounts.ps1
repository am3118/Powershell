function New-RandomPassword {
    param (
        [Parameter()]
        [int]$MinimumPasswordLength = 25,
        [Parameter()]
        [int]$MaximumPasswordLength = 26,
        [Parameter()]
        [int]$NumberOfAlphaNumericCharacters = (Get-Random -Maximum 12 -Minimum 5),
        [Parameter()]
        [switch]$ConvertToSecureString
    )
    Add-Type -AssemblyName 'System.Web'
    $length = Get-Random -Minimum $MinimumPasswordLength -Maximum $MaximumPasswordLength
    $password = [System.Web.Security.Membership]::GeneratePassword($length,$NumberOfAlphaNumericCharacters)
    if ($ConvertToSecureString.IsPresent) {
        ConvertTo-SecureString -String $password -AsPlainText -Force
    } else {
        $password
    }
}

Write-Host "Select input file"
Add-Type -AssemblyName System.Windows.Forms
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
$FileBrowser.filter = "Csv (*.csv)| *.csv"
[void]$FileBrowser.ShowDialog()
$users = import-csv $FileBrowser.FileName
$DomainController ="mksplai-dc01"
$ou = "OU=TechOps-Eng,OU=IT,DC=mksinternal,DC=com"
Write-Host -ForegroundColor Cyan "Working on AD Users"

$passwords = @{}

foreach($user in $users)
{
    Write-Host -ForegroundColor Green $user.Email
    $adUser = $null
    $adGroup = $null
    $aadGroup = $null
    $existingAdminAccount = $null
    try
    {
        $adUser = Get-ADUser -LDAPFilter "(mail=$($user.Email))" -ErrorAction Stop -Properties whencreated,memberof,employeeid,mail,title -server $DomainController
    } catch{
    }
    if($null -notlike $adUser) {
        $existingAdminAccount = Get-ADUser -LDAPFilter "(&(extensionAttribute1=$($adUser.employeeId))(cn=mks_*))" -Properties wwwhomepage,mail,extensionAttribute1,extensionAttribute7  -server $DomainController
        if($null -notlike $existingAdminAccount) {
            Write-Host -ForegroundColor Yellow "Existing Admin Account found for $($user.email)`: $($existingAdminAccount.DistinguishedName)"
        } else {
            Write-Host "Create new Admin Account for $($user.email)`."
            if($adUser.surname.Length -gt 15) {
                $admUserName = "mks_$($adUser.surname.Substring(0,15))$($adUser.GivenName[0])"
            } else {
                $admUserName = "mks_$($adUser.surname)$($adUser.GivenName[0])"
            }
            $conflictingAccount = $null
            try {
                $conflictingAccount = Get-ADUser $admUserName -ErrorAction SilentlyContinue
            } catch {
                ##do nothing
            }
            $x = 2
            while($null -notlike $conflictingAccount) {
                Write-Host -ForegroundColor Yellow "Conflicting Admin Account found for $admUserName`. Generating another name.`: $($conflictingAccount.DistinguishedName)"
                $conflictingAccount = $null
                if($adUser.surname.Length -gt (15 - $x + 1)) {
                    $admUserName = "mks_$($adUser.surname.Substring(0, (15 - $x + 1)))$($adUser.GivenName[0])$x"
                } else {
                    $admUserName = "mks_$($adUser.surname)$($adUser.GivenName[0])$x"
                }

                $conflictingAccount = Get-ADUser $admUserName -Server $DomainController
                $x++
                start-sleep 1
            }

            #$admUserName

            $randomPassword = New-RandomPassword
            $passwords.Add(($adUser.mail),$randomPassword)

            $secpasswd = $randomPassword | ConvertTo-SecureString -AsPlainText -Force
            
            New-ADUser -AccountPassword $secpasswd -CannotChangePassword:$false -ChangePasswordAtLogon:$true -PasswordNeverExpires:$false -DisplayName "$($adUser.GivenName) $($adUser.Surname) (ENG-ADM)" -Description "Administrator account created through $($user.Ticket) for TechOps or Engineering user for local admin rights to test stands and engineering machines." `
            -GivenName $adUser.GivenName -Name $admUserName -Path $ou -Enabled:$true -EmailAddress "$($admUserName)@mksinst.com" -Surname $adUser.surname -Office $user.Site `
            -UserPrincipalName "$($admUserName)@mksinst.com" -server $DomainController -KerberosEncryptionType:AES128,AES256
            
            Set-ADUser $admUserName -Replace @{wWWHomePage = $aduser.mail} -server $DomainController
            Set-ADUser $admUserName -Replace @{extensionAttribute1 = $aduser.employeeId} -server $DomainController
            Set-ADUser $admUserName -Replace @{extensionAttribute7 ="ENGOPS-ADM"} -server $DomainController
            Set-ADUser $admUserName -Replace @{title = $aduser.title} -server $DomainController
            Add-ADGroupMember -Identity "CN=SG-AdminAccounts,OU=Security Groups,OU=MKS,DC=mksinternal,DC=com" -Members $admUserName -server $DomainController
            Add-ADGroupMember -Identity "CN=AAD_O365_MFA_StandardUser,OU=AAD_MFA,OU=Office365,OU=Enterprise,DC=mksinternal,DC=com" -Members $admUserName -server $DomainController
            Add-ADGroupMember -Identity "CN=SG-ADM-EUC-TechOps-TempAdmins,OU=Security Groups,OU=MKS,DC=mksinternal,DC=com" -Members $admUserName -server $DomainController
        }
    } else {
        Write-Host -ForegroundColor Red "No AD User found for $($user.email)`."
        
        
        #New-ADUser -Path $ou -Name
    }
    
<#
    $SamAccountName = $user.Username
    $extensionAttribute1 = $user.extensionAttribute1
    $manager = $user.manager
    $Title = $user.title
    $wWWHomePage = $user.wWWHomePage
    $adGroup = $user.ADGroup
    $aadGroup = $user.AADGroup

 


    if ($User.username.length -gt 20)
    {
        $SamAccountName = $user.Username.substring(0,20)
    }

 

    if($null -like $adUser)
    {
        $secpasswd = ConvertTo-SecureString -String $user.Password -AsPlainText -Force

        New-ADUser -AccountPassword $secpasswd -CannotChangePassword:$false -ChangePasswordAtLogon:$true -PasswordNeverExpires:$false -DisplayName $user.DisplayName -Description "NAA" `
        -GivenName $user.UserName -Name $SamAccountName -Path 'OU=NewAccountStage,DC=mksinternal,DC=com' -Enabled:$true -EmailAddress "$($user.Username)@mksinst.com" `
        -City $user.City -Country $user.Country -StreetAddress $user.Street -State $user.State -OfficePhone $user.Phone -Office $user.Location `
        -UserPrincipalName "$($user.UserName)@mksinst.com" -server $DomainController

 

        Set-ADUser $samAccountName -Replace @{"Mailnickname" = $SamAccountName} -Server $DomainController

 

        Set-ADUser $SamAccountName -Replace @{wWWHomePage = "$wWWHomepage"} -server $DomainController
        Set-ADUser $SamAccountName -Replace @{extensionAttribute1 = "$extensionAttribute1"} -server $DomainController
        Set-ADUser $SamAccountName -Replace @{extensionAttribute7 ="IT-ADM"} -server $DomainController
        Set-ADUser $SamAccountName -Replace @{manager = "$manager"} -server $DomainController
        Set-ADUser $SamAccountName -Replace @{title = "$Title"} -server $DomainController
    }

 

    if($adUser.MemberOf -notcontains "CN=M365_TeamsRooms_240,OU=O365 Licensing Groups,OU=Office365,OU=Enterprise,DC=mksinternal,DC=com")
    {
        try
        {d
            Ad-ADGroupMember -Identity "CN=AAD_O365_MFA_StandardUser,OU=AAD_MFA,OU=Office365,OU=Enterprise,DC=mksinternal,DC=com" -Members $SamAccountName -server $DomainController
            Add-ADGroupMember -Identity "CN=SG-AdminAccounts,OU=Groups,OU=Enterprise,DC=mksinternal,DC=com" -Members $SamAccountName -server $DomainController
            Add-ADGroupMember -Identity "$adGroup" -Members $SamAccountName -server $DomainController
            Add-ADGroupMember -Identity "$aadGroup" -Members $SamAccountName -server $DomainController

        }
        catch
        {
            Write-Error "Failed to add user to room list DL. $($_.Error.Message)"
        }
    }
#>
}

$passwords | Out-GridView