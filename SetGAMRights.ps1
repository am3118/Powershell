$ous = get-content .\GAMOUs.txt

foreach($ou in $ous) {
    .\setrole.ps1 -dc MKSPLAI-DC01 -oustring $ou -role 'User-Manager' -group 'SG-ADM-EUC-GAM'
}