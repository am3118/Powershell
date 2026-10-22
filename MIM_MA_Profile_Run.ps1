[CmdletBinding()]
 Param (
 [switch]$Delta,
 [switch]$Full
 )

#Run Profile $RP in $MA agent
function Start_RunProfile($MA, $RP)
    {
     Write-Host "$($MA.Name) | $RP is executing"
     $result = $MA.Execute($RP);
     Write-Host "Finished $($result.ReturnValue)"    
    }


start-transcript c:\scripts\mimsync\transcript.txt
$Server = hostname
$MA_ADMAMKS = get-wmiobject -class "MIIS_ManagementAgent" -namespace "root\MicrosoftIdentityIntegrationServer" -computername $Server | ?{$_.name -eq "mksinternal.com"}
$MA_ADMANewport = get-wmiobject -class "MIIS_ManagementAgent" -namespace "root\MicrosoftIdentityIntegrationServer" -computername $Server | ?{$_.name -eq "newport.com"}
$MA_ADMAESI = get-wmiobject -class "MIIS_ManagementAgent" -namespace "root\MicrosoftIdentityIntegrationServer" -computername $Server | ?{$_.name -eq "esi.com"}

$MA_MIMMA = get-wmiobject -class "MIIS_ManagementAgent" -namespace "root\MicrosoftIdentityIntegrationServer" -computername $Server | ?{$_.name -eq "MIMMA"}
$MA_PH = get-wmiobject -class "MIIS_ManagementAgent" -namespace "root\MicrosoftIdentityIntegrationServer" -computername $Server | ?{$_.name -eq "PersonHUB"}

#Run Profiles short names
$FI = "Full Import"
$FS = "Full Synchronization"
$DI = "Delta Import"
$DS = "Delta Synchronization"
$EX = "Export"
<#
$RPlist_ADMA1 = @($DI); $ExTimeOut1 = 7
$RPlist_PH1 = @($DI); $ExTimeOut1 = 7
$RPlist_PH2 = @($EX, $DI, $DS); $ExTimeOut2 = 7
$RPlist_ADMA2 = @($EX, $DI, $DS); $ExTimeOut2 = 7
$RPlist_MIMMA = @($EX, $DI, $DS);$ExTimeOut3 = 3
$RPlist_ADMA1_FS = @($DI, $DS); $ExTimeOut1_FS = 7
$RPlist_ADMA2_FS = @($EX, $DI, $DS); $ExTimeOut2_FS = 7
$RPlist_PH1_FS = @($FI, $FS); $ExTimeOut1_FS = 7
$RPlist_PH2_FS = @($EX, $DI, $DS); $ExTimeOut2_FS = 7
$RPlist_MIMMA_FS = @($EX, $DI, $DS); $ExTimeOut3_FS = 7

#>


#do timeout between Export and Import profiles

Start_RunProfile $MA_MIMMA $DI
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMAMKS $DI
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMANewport $DI
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMAESI $DI
{Start-Sleep -s 7}
Start_RunProfile $MA_PH $FI
{Start-Sleep -s 7}
Start_RunProfile $MA_PH $DS
{Start-Sleep -s 7}

Start_RunProfile $MA_MIMMA $DS
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMAMKS $DS
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMANewport $DS
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMAESI $DS
{Start-Sleep -s 7}


Start_RunProfile $MA_MIMMA $EX
{Start-Sleep -s 7}
Start_RunProfile $MA_MIMMA $DI
{Start-Sleep -s 7}
Start_RunProfile $MA_MIMMA $DS
{Start-Sleep -s 7}

Start_RunProfile $MA_ADMAMKS $EX
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMAMKS $DI
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMAMKS $DS
{Start-Sleep -s 7}

Start_RunProfile $MA_ADMANewport $EX
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMANewport $DI
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMANewport $DS
{Start-Sleep -s 7}

Start_RunProfile $MA_ADMAESI $EX
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMAESI $DI
{Start-Sleep -s 7}
Start_RunProfile $MA_ADMAESI $DS
{Start-Sleep -s 7}

Start_RunProfile $MA_MIMMA $EX
{Start-Sleep -s 7}
Start_RunProfile $MA_MIMMA $DI
{Start-Sleep -s 7}
Start_RunProfile $MA_MIMMA $DS
{Start-Sleep -s 7}

Start_RunProfile $MA_PH $EX
{Start-Sleep -s 7}
Stop-Transcript