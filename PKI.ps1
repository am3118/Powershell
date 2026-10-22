param(
[Parameter(Mandatory)]
[string]$CsrFullPath,
[Parameter(Mandatory)]
[string]$CertificateTemplate,
[Parameter(Mandatory)]
[string]$RequestorEmail
)
Import-Module PSPKI
$JcertAuthority = get-CertificationAuthority mksplai-pkiica.mksinternal.com
 
$ActualCerticateTemplates = Get-CertificateTemplate|select displayname,name
if($($ActualCerticateTemplates.displayname) -notcontains $CertificateTemplate){
	write-host "$CertificateTemplate - template not found" -foregroundcolor magenta;break
}
$CertificateTemplateName = ($ActualCerticateTemplates|where{$_.displayname -eq $CertificateTemplate}).name
$Attribute = "CertificateTemplate:"+$CertificateTemplateName
 
if($CsrFullPath -match '^\.\\\w+\.*\w+'){$CsrFullPath = $CsrFullPath -replace '\.\\',"$PWD\"}
 
$od = (get-date -format yyyy-MM-dd-hh-mm)
 
$q = Submit-CertificateRequest -path $csrFullPath -CertificationAuthority $JcertAuthority -Attribute $Attribute
$CertID = $q.RequestID
 
 
if($?){
	$qr = new-object psobject -property @{
		Date = $od
		CertID = $CertID
		CertificateTemplate = $CertificateTemplate
		CertIssuedPath = $(($pwd.path)+"\" +$CertID.cer)
		RequestedBy = $RequestorEmail
	}
	if($q.status -eq "issued"){"-----BEGIN CERTIFICATE-----" | Out-File $PWD\$CertID.cer
	((Get-IssuedRequest -CertificationAuthority $JcertAuthority -RequestID $CertID -Property "RawCertificate")."RawCertificate").trim("`r`n") | 
	Out-File $pwd\$CertID.cer -Append
	"-----END CERTIFICATE-----" | Out-File $PWD\$CertID.cer -Append
	write-host "See $PWD\$CertID.cer" -foregroundcolor green
	if(test-path .\output.xml){
		[array]$output = import-clixml .\output.xml
		[array]$output += $qr
	}
	else{$output = $qr}
	$output|export-clixml .\output.xml
	}
 
	Elseif($q.status -eq "UnderSubmission"){
	$JcertAuthority|Get-PendingRequest -ID $CertID|Approve-CertificateRequest
	If(!$?){$q;write-host "Ask a CA administrator to issue the request $CertID" -foregroundcolor magenta;break}
		"-----BEGIN CERTIFICATE-----" | Out-File $PWD\$CertID.cer
	((Get-IssuedRequest -CertificationAuthority $JcertAuthority -RequestID $CertID -Property "RawCertificate")."RawCertificate").trim("`r`n") | 
	Out-File $pwd\$CertID.cer -Append
	"-----END CERTIFICATE-----" | Out-File $PWD\$CertID.cer -Append
	write-host "See $PWD\$CertID.cer" -foregroundcolor green
	if(test-path .\output.xml){
		[array]$output = import-clixml .\output.xml
		[array]$output += $request
	}
	else{$output = $request}
	$output|export-clixml .\output.xml	
	}
	else{$q}
}