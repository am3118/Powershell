Import-Module AzureADPreview
connect-azuread

#Get-AzureADApplication -SearchString MKS_GALSync_Atotech
$appObjectId = '7542046f-8372-4fcc-b174-39b6171ecc47'
$app = Get-AzureADApplication -ObjectId $appObjectId
$appName = $app.DisplayName
$certPassword = 'SomeReallyG00dPasswordHere!MKS'

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
