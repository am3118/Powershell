Write-Host "Office 365 GA Credentials"
Connect-AzureAD

# Variables
$appName = 'MKS_GALSync_Atotech'
$certPassword = 'SomeReallyG00dPasswordHere!MKS'

## Get the Office 365 Exchange Online API details.
$api = (Get-AzureADServicePrincipal -Filter "AppID eq '00000002-0000-0ff1-ce00-000000000000'")

## Get the API permission ID
$permission = $api.AppRoles | Where-Object { $_.Value -eq 'Exchange.ManageAsApp' }

## Build the API permission object (TYPE: Role = Application, Scope = User)
$apiPermission = [Microsoft.Open.AzureAD.Model.RequiredResourceAccess]@{
    ResourceAppId  = $api.AppId ;
    ResourceAccess = [Microsoft.Open.AzureAD.Model.ResourceAccess]@{
        Id   = $permission.Id ;
        Type = "Role"
    }
}

## Register the new Azure AD App with API Permissions
$myApp = New-AzureADApplication -DisplayName $appName -ReplyUrls 'http://localhost' -RequiredResourceAccess $apiPermission

## Enable the Service Principal
$mySP = New-AzureADServicePrincipal -AppID $myApp.AppID

## Display the new app properties
$myApp | export-csv .\exchangeadminapp.csv

## Number of years of certificate validity
$certYears = 4

## Certificate (PFX) password
$CertificateFilePath = (Resolve-Path ".\$($appName).cer" -ErrorAction SilentlyContinue).Path
if(-not ($CertificateFilePath))
{
    .\Create-SelfSignedCertificate.ps1 -CommonName $appName `
    -StartDate (Get-Date).AddDays(-1) `
    -EndDate (Get-Date).AddYears($certYears) `
    -Password (ConvertTo-SecureString $certPassword -AsPlainText -Force) `
    -Force
}

## Get the certificate file (.CER)
$CertificateFilePath = (Resolve-Path ".\$($appName).cer").Path

## Create a new certificate object
$cer = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cer.Import("$($CertificateFilePath)")
$bin = $cer.GetRawCertData()
$base64Value = [System.Convert]::ToBase64String($bin)
$bin = $cer.GetCertHash()
$base64Thumbprint = [System.Convert]::ToBase64String($bin)

## Upload and assign the certificate to application in AzureAD
$null = New-AzureADApplicationKeyCredential -ObjectId $myApp.ObjectID `
-CustomKeyIdentifier $base64Thumbprint `
-Type AsymmetricX509Cert -Usage Verify `
-Value $base64Value `
-StartDate ($cer.NotBefore) `
-EndDate ($cer.NotAfter)

## The role to assign to your app
$directoryRole = 'Exchange Service Administrator'

## Find the ObjectID of 'Exchange Service Administrator'
$RoleId = (Get-AzureADDirectoryRole | ? {$_.DisplayName -eq "Exchange Administrator"}).ObjectId

## Add the service principal to the directory role
Add-AzureADDirectoryRoleMember -ObjectId $RoleId -RefObjectId $mySP.ObjectID -Verbose

## Get the TenantID
$tenantID = (Get-AzureADTenantDetail).ObjectID

## Browse this URL
$consentURL = "https://login.microsoftonline.com/$tenantID/adminconsent?client_id=$($myApp.AppId)"


Start-Process $consentURL
