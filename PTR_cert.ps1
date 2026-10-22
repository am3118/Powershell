$cert=New-SelfSignedCertificate -Subject "CN=TRAP_cert" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -NotAfter (Get-Date).AddYears(3)
$bin = $cert.RawData
$base64Value = [System.Convert]::ToBase64String($bin)
$bin = $cert.GetCertHash()
$base64Thumbprint = [System.Convert]::ToBase64String($bin)
$keyid = [System.Guid]::NewGuid().ToString()
$jsonObj = @{customKeyIdentifier=$base64Thumbprint;keyId=$keyid;type="AsymmetricX509Cert";usage="Verify";value=$base64Value}
$keyCredentials=ConvertTo-Json @($jsonObj) | Out-File "keyCredentials.txt"
Export-Certificate -Cert $cert -FilePath .\cert.cer
$mypwd = ConvertTo-SecureString -String 'r954f8@~0NnQG,oZt+Nk=D:9~5' -Force -AsPlainText
Export-PfxCertificate -cert $cert -FilePath .\cert.pfx -Password $mypwd