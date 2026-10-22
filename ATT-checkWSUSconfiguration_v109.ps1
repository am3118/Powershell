# ATT-checkWSUSconfiguration.ps1
# Script to check the WSUS configuration inside a windows task (deployed via GPP)
# author: Sebastian Schlueterbusch, BSH IT Solutions GmbH (AN ALLGEIER COMPANY)
# date: 30.06.2017
#
# V1.01 - Added WSUS Module Import for Windows 2008(R2) WSUS Servers
# V1.02 - Module Import just for Windows 2008
# V1.03 - Special config for upstream server
# V1.04 - New Proxy configuration (Zscaler) and port variable
# V1.05 - Changed BitsDownloadPriorityForeground to $False
#         EU + AMAS --> Proxy: ww-proxy01.att.chem.corp.local; Port: 9480; BITSForeground--> False
#         ASPA --> bleibt att-" + $ProxyLocation + "-proxy." + $Domain; Port: 8020; BITSForeground --> True   
# V1.06 - New Proxy configuration: worldwide ww-proxy01.att.chem.corp.local
# V1.07 - New Upstream server BRLNAP97
# V1.09 - New Upstream server EUFRAP394
#
# Exit codes of script:
#
# exit 0  - nothing done / configuration is compliant
# exit 1  - changes were made in WSUS configuration or subscription
# exit 10 - error exemption happens somewhere without aborting script
# exit 11 - domain could not be identified / proxy name could not be built
# exit 12 - WSUS config or subscription information could not be read
# exit 13 - WSUS config changes could not be saved / applied
# exit 14 - WSUS subscription changes could not be saved / applied
#



#
$version = "1.09"

# parameters
$Logfile = ((split-path -parent $MyInvocation.MyCommand.Definition) + "\" + ($MyInvocation.MyCommand.Name).Substring(0,($MyInvocation.MyCommand.Name).Length-4) + ".log" )

$wsusClientsInstallUpdatesRedPercent = 75        # Error-Level (in percent) for installed update
$wsusClientsInstallUpdatesGreenPercent = 50      # Warning-Level (in percent) for installed update
$wsusSilentClientsRedPercent = 75                # Error-Level (in percent) for silent clients
$wsusSilentClientsGreenPercent = 50              # Warning-Level (in percent) for silent clients
$wsusSilentClientsDays = 30                      # days after clients are identified as "silent"

$changelog = @()
$currentdate = get-date

$selfOS = (Get-WmiObject -class Win32_OperatingSystem).Caption

If ($selfOS -match "2008") {

    $selfhostname = ((Get-WmiObject -Class Win32_ComputerSystem).Name + "." + (Get-WmiObject -Class Win32_ComputerSystem).Domain)

    Import-Module C:\Windows\System32\WindowsPowerShell\v1.0\Modules\WSUSAdministrativeModule\PoshWSUS1_1.psm1
    Connect-WSUSServer -WsusServer $selfhostname -port 8530

}


# functions

# function to check and correct hosts-file entry
function attHOSTSentry ([string]$ip, [string]$hostname){
    $file = "C:\Windows\System32\drivers\etc\hosts"
    $newLines = @()
    $line_hostlist = @()
    $nonewline = 0
    foreach ($line in (Get-Content $file)) { 
        
        If ($line -match "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}") { 
            If ($line -match $hostname -or $line -match $hostname.ToUpper() -or $line -match $hostname.ToLower()) {
            # Hostname is already in HOSTS file
                If ($line.Split(" ")[0] -match "[a-zA-Z]") { 
                    $line_temphost = ($line.Split(" ")[0].Split("`t")) 
                    $line_temphost | ? { $_ -match "[a-zA-Z]" } | % { $hostentry = $_.Trim().ToLower() }
                    $line_tempip = ($line.Split(" ")[0].Split("`t"))[0]
                    $line_hostlist = ($line.Split(" ") | ? { $_ -notmatch "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"  }  ) 
                    $line_hostlist += $hostentry
                } 
                Else {
                    $line_hostlist = ($line.Split(" ") | ? { $_ -notmatch "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"  })
                    $line_tempip = $line.Split(" ")[0]
                }

                $newline_hostlist = ""
                $checkip = 0
                $line_hostlist | ? { $_.Trim() } | % {  

                    $hostalias = $_.Trim().tolower()
                    If ($hostname.ToLower() -eq $hostalias) {
                        If ($line -match $ip) {
                            # Entry is already as needed
                            $nochangeneeded = (Get-Content $file)
                        } Else {
                            $checkip = 1

                        }
                    } Else {
                        If ($line -match $ip) { 
                        
                        } Else {
                        $checkip = 1
                        }
                        $newline_hostlist += ($_.Trim() + " ")

                    }

                }

                If ($checkip -eq 1) {
                    $newLines += ($line_tempip + " " + $newline_hostlist )
                } Else {
                    $newLines += ($line_tempip + " " + $newline_hostlist + " " + $hostname )
                    $nonewline = 1
                }
                




            } 
            Else {
                # Hostname is not in HOSTS file
                If ($line -match $ip) {
                    $newLines += ($line + " " + $hostname)
                    $nonewline = 1
                } Else {
                    #$newLines += ($line + " " + $hostname)
                    #$newLines += ($ip + " " + $hostname)
                    $newLines += $line
                }
            }
        }
        Else {
            $newLines += $line
        }
    }
    If ($nonewline -ne 1) { $newLines += ($ip + " " + $hostname) }

    If ($nochangeneeded) { 
        return 0
    } Else { 
        $newLines | Out-File -encoding ASCII $file
        return 1
    }
}

# build proxy name

    $ProxyName = "ww-proxy01.att.chem.corp.local"
    $ProxyPort = "9480"
    $BITSFG = $False








# get WSUS configuration and subcription information
$ATTWsus = Get-WSUSServer
$ATTWsusConfig = $ATTWsus.GetConfiguration()
$ATTWsusSubscription = $ATTWsus.GetSubscription()
$ATTWsusConfigChanges = 0
$ATTWsusSubscriptionChanges = 0
# if WSUS configuration or subscription information could not be read exit with code "12"
If (-Not($ATTWsusConfig) -Or -Not($ATTWsusSubscription)) { 
    $info = "EXIT 12 - ERROR: WSUS config or subscription could not be read"
    $changelog += ("[" + (get-date -format s) + "] " + $info)
    Write-Host $info -ForegroundColor Magenta
    $changelog >> $Logfile
    exit 12 
}

# Check HOSTS file
$wsusHOSTSentry = attHOSTSentry 10.55.0.240 EUFRAP394
If ($wsusHOSTSentry -ne 0) { 
    $info = "HOSTS-File Check discovered issue..."
    Write-Host $info -NoNewline; Write-Host "Corrected!" -ForegroundColor Green
    $changelog += ("[" + (get-date -format s) + "] " + $info + "Corrected!")
}


If ($ATTWsusConfig.IsReplicaServer -eq $False) {
    # WSUS is Upstream-Server
    If($ATTWsusConfig.AllUpdateLanguagesEnabled -ne $false) { $info = ("Mismatch detected: AllUpdateLanguagesEnabled = " + $ATTWsusConfig.AllUpdateLanguagesEnabled); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.AllUpdateLanguagesEnabled = $False;$ATTWsusConfigChanges++ }
    If($ATTWsusConfig.GetEnabledUpdateLanguages() -notmatch "en") {$info = ("Mismatch detected: GetEnabledUpdateLanguages = " + $ATTWsusConfig.GetEnabledUpdateLanguages()); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.SetEnabledUpdateLanguages("en");$ATTWsusConfigChanges++}
    If($ATTWsusConfig.UseProxy -ne $true) { $info = ("Mismatch detected: UseProxy = " + $ATTWsusConfig.UseProxy); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.UseProxy = $true;$ATTWsusConfigChanges++ }
    If($ATTWsusConfig.ProxyName -ne $ProxyName) {$info = ("Mismatch detected: ProxyName = " + $ATTWsusConfig.ProxyName); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.ProxyName = $ProxyName;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.ProxyServerPort -ne $ProxyPort) {$info = ("Mismatch detected: ProxyServerPort = " + $ATTWsusConfig.ProxyServerPort); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.ProxyServerPort = $ProxyPort;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.TargetingMode -ne "Client") {$info = ("Mismatch detected: TargetingMode = " + $ATTWsusConfig.TargetingMode); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.TargetingMode = "Client";$ATTWsusConfigChanges++}
    If($ATTWsusConfig.DownloadUpdateBinariesAsNeeded -ne $true) {$info = ("Mismatch detected: DownloadUpdateBinariesAsNeeded = " + $ATTWsusConfig.DownloadUpdateBinariesAsNeeded); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.DownloadUpdateBinariesAsNeeded = $true;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.DownloadExpressPackages -ne $false) {$info = ("Mismatch detected: DownloadExpressPackages = " + $ATTWsusConfig.DownloadExpressPackages); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.DownloadExpressPackages = $false;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.GetContentFromMU -ne $true) {$info = ("Mismatch detected: GetContentFromMU = " + $ATTWsusConfig.GetContentFromMU); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.GetContentFromMU = $true;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HostBinariesOnMicrosoftUpdate -ne $true) {$info = ("Mismatch detected: HostBinariesOnMicrosoftUpdate = " + $ATTWsusConfig.HostBinariesOnMicrosoftUpdate); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HostBinariesOnMicrosoftUpdate = $false;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.BitsDownloadPriorityForeground -ne $BITSFG) {$info = ("Mismatch detected: BitsDownloadPriorityForeground = " + $ATTWsusConfig.BitsDownloadPriorityForeground); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.BitsDownloadPriorityForeground = $BITSFG;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HmClientsInstallUpdatesGreenPercent -ne $wsusClientsInstallUpdatesGreenPercent) {$info = ("Mismatch detected: HmClientsInstallUpdatesGreenPercent = " + $ATTWsusConfig.HmClientsInstallUpdatesGreenPercent); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HmClientsInstallUpdatesGreenPercent = $wsusClientsInstallUpdatesGreenPercent;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HmClientsInstallUpdatesRedPercent -ne $wsusClientsInstallUpdatesRedPercent) {$info = ("Mismatch detected: HmClientsInstallUpdatesRedPercent = " + $ATTWsusConfig.HmClientsInstallUpdatesRedPercent); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HmClientsInstallUpdatesRedPercent = $wsusClientsInstallUpdatesRedPercent;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HmClientsSilentGreenPercent -ne $wsusSilentClientsGreenPercent) {$info = ("Mismatch detected: HmClientsSilentGreenPercent = " + $ATTWsusConfig.HmClientsSilentGreenPercent); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HmClientsSilentGreenPercent = $wsusSilentClientsGreenPercent;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HmClientsSilentRedPercent -ne $wsusSilentClientsRedPercent) {$info = ("Mismatch detected: HmClientsSilentRedPercent = " + $ATTWsusConfig.HmClientsSilentRedPercent); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HmClientsSilentRedPercent = $wsusSilentClientsRedPercent;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HmClientsSilentDays  -ne $wsusSilentClientsDays) {$info = ("Mismatch detected: HmClientsSilentDays = " + $ATTWsusConfig.HmClientsSilentDays); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HmClientsSilentDays = $wsusSilentClientsDays;$ATTWsusConfigChanges++}
} Else {
# Checks on WSUS config
    If($ATTWsusConfig.AllUpdateLanguagesEnabled -ne $false) { $info = ("Mismatch detected: AllUpdateLanguagesEnabled = " + $ATTWsusConfig.AllUpdateLanguagesEnabled); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.AllUpdateLanguagesEnabled = $False;$ATTWsusConfigChanges++ }
    If($ATTWsusConfig.GetEnabledUpdateLanguages() -notmatch "en") {$info = ("Mismatch detected: GetEnabledUpdateLanguages = " + $ATTWsusConfig.GetEnabledUpdateLanguages()); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.SetEnabledUpdateLanguages("en");$ATTWsusConfigChanges++}
    If($ATTWsusConfig.UseProxy -ne $true) { $info = ("Mismatch detected: UseProxy = " + $ATTWsusConfig.UseProxy); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.UseProxy = $true;$ATTWsusConfigChanges++ }
    If($ATTWsusConfig.ProxyName -ne $ProxyName) {$info = ("Mismatch detected: ProxyName = " + $ATTWsusConfig.ProxyName); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.ProxyName = $ProxyName;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.ProxyServerPort -ne $ProxyPort) {$info = ("Mismatch detected: ProxyServerPort = " + $ATTWsusConfig.ProxyServerPort); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.ProxyServerPort = $ProxyPort;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.TargetingMode -ne "Client") {$info = ("Mismatch detected: TargetingMode = " + $ATTWsusConfig.TargetingMode); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.TargetingMode = "Client";$ATTWsusConfigChanges++}
    If($ATTWsusConfig.DownloadUpdateBinariesAsNeeded -ne $true) {$info = ("Mismatch detected: DownloadUpdateBinariesAsNeeded = " + $ATTWsusConfig.DownloadUpdateBinariesAsNeeded); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.DownloadUpdateBinariesAsNeeded = $true;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.DownloadExpressPackages -ne $false) {$info = ("Mismatch detected: DownloadExpressPackages = " + $ATTWsusConfig.DownloadExpressPackages); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.DownloadExpressPackages = $false;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.GetContentFromMU -ne $true) {$info = ("Mismatch detected: GetContentFromMU = " + $ATTWsusConfig.GetContentFromMU); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.GetContentFromMU = $true;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HostBinariesOnMicrosoftUpdate -ne $false) {$info = ("Mismatch detected: HostBinariesOnMicrosoftUpdate = " + $ATTWsusConfig.HostBinariesOnMicrosoftUpdate); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HostBinariesOnMicrosoftUpdate = $false;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.BitsDownloadPriorityForeground -ne $BITSFG) {$info = ("Mismatch detected: BitsDownloadPriorityForeground = " + $ATTWsusConfig.BitsDownloadPriorityForeground); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.BitsDownloadPriorityForeground = $BITSFG;$ATTWsusConfigChanges++}
    
    If($ATTWsusConfig.HmClientsInstallUpdatesGreenPercent -ne $wsusClientsInstallUpdatesGreenPercent) {$info = ("Mismatch detected: HmClientsInstallUpdatesGreenPercent = " + $ATTWsusConfig.HmClientsInstallUpdatesGreenPercent); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HmClientsInstallUpdatesGreenPercent = $wsusClientsInstallUpdatesGreenPercent;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HmClientsInstallUpdatesRedPercent -ne $wsusClientsInstallUpdatesRedPercent) {$info = ("Mismatch detected: HmClientsInstallUpdatesRedPercent = " + $ATTWsusConfig.HmClientsInstallUpdatesRedPercent); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HmClientsInstallUpdatesRedPercent = $wsusClientsInstallUpdatesRedPercent;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HmClientsSilentGreenPercent -ne $wsusSilentClientsGreenPercent) {$info = ("Mismatch detected: HmClientsSilentGreenPercent = " + $ATTWsusConfig.HmClientsSilentGreenPercent); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HmClientsSilentGreenPercent = $wsusSilentClientsGreenPercent;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HmClientsSilentRedPercent -ne $wsusSilentClientsRedPercent) {$info = ("Mismatch detected: HmClientsSilentRedPercent = " + $ATTWsusConfig.HmClientsSilentRedPercent); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HmClientsSilentRedPercent = $wsusSilentClientsRedPercent;$ATTWsusConfigChanges++}
    If($ATTWsusConfig.HmClientsSilentDays  -ne $wsusSilentClientsDays) {$info = ("Mismatch detected: HmClientsSilentDays = " + $ATTWsusConfig.HmClientsSilentDays); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta; $ATTWsusConfig.HmClientsSilentDays = $wsusSilentClientsDays;$ATTWsusConfigChanges++}
}

# If something changed in WSUS config do save
If($ATTWsusConfigChanges -ne 0) {
    Try {
        Write-Host "Configuration changes in WSUS serverconfig detected!"
        Write-Host "Saving new configuration..."
        $ATTWsusConfig.Save() 

        Write-Host "Restarting WSUS service..."
        net stop WSUSService
        Start-Sleep 1
        net start WSUSService
    }
    Catch {
        # If somethin went wront during saving config exit with code "13"
        $info = "EXIT 13 - ERROR: Error while saving / applying WSUS configuration"
        $changelog += ("[" + (get-date -format s) + "] " + $info)
        Write-Host $info -ForegroundColor Magenta
        $changelog >> $Logfile
        exit 13
    }
    Write-Host "Done" -ForegroundColor Green
}



# Checks on WSUS subscription
    If ($ATTWsusSubscription.SynchronizeAutomatically -ne $true) {$info = ("Mismatch detected: SynchronizeAutomatically = " + $ATTWsusSubscription.SynchronizeAutomatically); Write-Host $info -ForegroundColor Magenta; $ATTWsusSubscription.SynchronizeAutomatically = $true;$ATTWsusSubscriptionChanges++}
    $currentdate = get-date
    $checkDate = ((($currentdate).ToUniversalTime().Date.Add($ATTWsusSubscription.SynchronizeAutomaticallyTimeOfDay)).ToLocalTime())
    $checkTime = $checkDate - ($checkDate).Date
    If ($checkTime.Hours -ne 2 -or $checkTime.Minutes -ne 10) {  
        $info = ("Mismatch detected: SynchronizeAutomaticallyTimeOfDay = " + $ATTWsusSubscription.SynchronizeAutomaticallyTimeOfDay)
        $changelog += ("[" + (get-date -format s) + "] " + $info)
        Write-Host $info -ForegroundColor Magenta
        $localSyncTime = ($currentdate).Date
        $localSyncHours = New-TimeSpan -Hours 2 -Minutes 10
        $localSyncTime = $localSyncTime.Add($localSyncHours).ToUniversalTime()
        $localSyncHours = ($localSyncTime - ($localSyncTime).Date)

        $ATTWsusSubscription.SynchronizeAutomaticallyTimeOfDay = $localSyncHours
        $ATTWsusSubscriptionChanges++
    }
    
    If ($ATTWsusSubscription.NumberOfSynchronizationsPerDay -ne 1) {$info = ("Mismatch detected: NumberOfSynchronizationsPerDay = " + $ATTWsusSubscription.NumberOfSynchronizationsPerDay); $changelog += ("[" + (get-date -format s) + "] " + $info); Write-Host $info -ForegroundColor Magenta;$ATTWsusSubscription.NumberOfSynchronizationsPerDay=1;$ATTWsusSubscriptionChanges++}


# If something changed do save
If($ATTWsusSubscriptionChanges -ne 0) {
    Try {
        Write-Host "Configuration changes in Subscription detected!"
        Write-Host "Saving new subscription configuration..."
        $ATTWsusSubscription.Save() 
        Write-Host "Starting new synchronization..."
        $ATTWsusSubscription.StartSynchronization()
    }
    Catch {
        # If somethin went wront during saving subscription exit with code "14"
        $info = "EXIT 14 - ERROR: Error while saving / applying WSUS subscription"
        $changelog += ("[" + (get-date -format s) + "] " + $info)
        Write-Host $info -ForegroundColor Magenta
        $changelog >> $Logfile
        exit 14  
    }
    Write-Host "Done" -ForegroundColor Green

}

# If errors occured during script processing without aborting exit with code "10"
If ($error.Count -gt 0) { 
    $info = "EXIT 10 - WARNING: script ended but errors occured"
    $changelog += ("[" + (get-date -format s) + "] " + $info)
    Write-Host $info -ForegroundColor Magenta
    $changelog >> $Logfile
    exit 10 
}
# If changes were made in WSUS config or subscription exit with code "1"
If ($ATTWsusConfigChanges -ne 0 -or $ATTWsusSubscriptionChanges -ne 0 -or $wsusHOSTSentry -ne 0) { 
    $info = "EXIT 1 - INFO: changes wer made"
    $changelog += ("[" + (get-date -format s) + "] " + $info)
    Write-Host $info -ForegroundColor Magenta
    $changelog >> $Logfile
    exit 1 
}
# If nothing were changed exit with code "0"

exit 0