Clear-Host

#This function builds the array
Function AppArray($SPDisplayname,$SPExpiration,$SPObjectID,$SPAppID,$ADDisplayname,$ADObjectID,$ADAppID,$ADClientSecretExpiration,$ADCertExpiration){
    $global:AllApps += @(
        $AppObject = New-Object -TypeName psobject
        $AppObject | Add-Member -MemberType NoteProperty -Name SPDisplayname -Value $SPDisplayname
        $AppObject | Add-Member -MemberType NoteProperty -Name SPExpiration -Value $SPExpiration
        $AppObject | Add-Member -MemberType NoteProperty -Name SPObjectID -Value $SPObjectID       
        $AppObject | Add-Member -MemberType NoteProperty -Name SPAppID -Value $SPAppID
        $AppObject | Add-Member -MemberType NoteProperty -Name ADDisplayname -Value $ADDisplayname
        $AppObject | Add-Member -MemberType NoteProperty -Name ADObjectID -Value $ADObjectID
        $AppObject | Add-Member -MemberType NoteProperty -Name ADAppID -Value $ADAppID
        $AppObject | Add-Member -MemberType NoteProperty -Name ADClientSecretExpiration -Value $ADClientSecretExpiration
        $AppObject | Add-Member -MemberType NoteProperty -Name ADCertExpiration -Value $ADCertExpiration
        $AppObject
    )
}

#Connects to Azure
If($connect -eq $null){$connect = Connect-AzureAD}

#Pulls all the Service Principals and AD Applications
$ALL_AZADServicePrincipals = Get-AzureADServicePrincipal -all:$true | sort-object displayname
$ALL_AZADApplications = Get-AzureADApplication -all:$true | sort-object displayname

#This goes through all the Service Principals and identifies any corresponding App Registrations
ForEach($AZADServicePrincipal in $ALL_AZADServicePrincipals){
    
    #Checks for expiration
    $SPexpiration = ($AZADServicePrincipal | Select-Object -ExpandProperty passwordcredentials | Select-Object -ExpandProperty enddate | Sort-Object) -join ";"
    If($SPexpiration -notlike "*/*"){$SPexpiration = $null}

    #Checks for a corresponding App Registration
    $AZADApplication = $null
    $AZADApplication = $ALL_AZADApplications | Where-Object appid -eq $AZADServicePrincipal.appid

    If($AZADApplication -ne $null){
        $ADDisplayname = $AZADApplication.displayname
        $ADObjectID = $AZADApplication.objectID
        $ADAppID = $AZADApplication.AppID

     #Checks for client secret expiration on the corresponding App Registration
     $ADClientSecretExpiration = $null     
     $ADClientSecretExpiration = ($AZADApplication | Select-Object -ExpandProperty passwordcredentials | Select-Object -ExpandProperty enddate | Sort-Object) -join ";"     
     If($ADClientSecretExpiration -notlike "*/*"){$ADClientSecretExpiration = $null}

     #Checks for certificate expiration on the corresponding App Registration
     $ADCertExpiration = $null
     $ADCertexpiration = ($AZADApplication | Select-Object -ExpandProperty KeyCredentials | Select-Object -ExpandProperty enddate | Sort-Object) -join ";"
     If($ADCertexpiration -notlike "*/*"){$ADCertexpiration = $null}
    }Else{
        $ADDisplayname = $null
        $ADObjectID = $null
        $ADAppID = $null
        $ADClientSecretExpiration = $null
        $ADCertExpiration = $null
    }

    #Calls the function to build the array
    AppArray -SPDisplayname $AZADServicePrincipal.displayname -SPExpiration $SPexpiration -SPObjectID $AZADServicePrincipal.ObjectId -SPAppID $AZADServicePrincipal.AppId -ADDisplayname $ADDisplayname -ADObjectID $ADObjectID -ADAppID $ADAppID -ADClientSecretExpiration $ADClientSecretExpiration -ADCertExpiration $ADCertExpiration
}

#This finds any app registrations that don't have a corresponding Service Principal and adds them to the $AllApps array
ForEach($AZADApplication in $ALL_AZADApplications){
    If($AllApps | Where-Object spappid -eq $AZADApplication.appid){}Else{

     #Checks for client secret expiration
     $ADClientSecretExpiration = $null
     $ADClientSecretExpiration = ($AZADApplication | Select-Object -ExpandProperty passwordcredentials | Select-Object -ExpandProperty enddate | Sort-Object) -join ";"
     If($ADClientSecretExpiration -notlike "*/*"){$ADClientSecretExpiration = $null}

     #Checks for certificate expiration
     $ADCertExpiration = $null
     $ADCertexpiration = ($AZADApplication | Select-Object -ExpandProperty KeyCredentials | Select-Object -ExpandProperty enddate | Sort-Object) -join ";"
     If($ADCertexpiration -notlike "*/*"){$ADCertexpiration = $null} 

        #Calls the function to build the array
        AppArray -SPDisplayname $null -SPExpiration $null -SPObjectID $null -SPAppID $null -ADDisplayname $AZADApplication.DisplayName -ADObjectID $AZADApplication.ObjectID -ADAppID $AZADApplication.AppID -ADClientSecretExpiration $ADClientSecretExpiration -ADCertExpiration $ADCertExpiration
    }
}

#Export the results
$date = Get-Date -Format yyyyMMdd
$AllApps| Where-Object {($_.spexpiration -ne $null) -or ($_.ADClientSecretExpiration -ne $null) -or ($_.ADCertExpiration -ne $null)} | Export-Csv -Path "C:\temp\MSD_Enterpriseapps_Feb26-2025.csv" -NoTypeInformation