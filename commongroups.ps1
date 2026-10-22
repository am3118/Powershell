$user1Groups = Get-DistributionGroup -ResultSize Unlimited | Where-Object { (Get-DistributionGroupMember $_.Identity).PrimarSmtpAddress -contains "John.TC.Lee@mksinst.com" }
$user2Groups = Get-DistributionGroup -ResultSize Unlimited | Where-Object { (Get-DistributionGroupMember $_.Identity).PrimarySmtpAddress -contains "sean.bos@mksinst.com" }
$commonGroups = $user1Groups.Name | Where-Object { $user2Groups.Name -contains $_ }
$commonGroups | Export-Csv -Path "c:\temp\leebos.csv" -NoTypeInformation