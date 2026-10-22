$permissions = New-CustomPermissions `
    -Users 'robert.levin@mksinst.com', 'joe.volpe@mksinst.com' `
    -Permissions Reviewer

$params = @{
    Path              = 'C:\9\SSL-RACIchart.xlsx'
    LabelId           = '86fa3a00-6c72-4ca5-90d9-035c6217dad9'
    CustomPermissions = $permissions
}

Set-FileLabel @params

# Inspect the resulting label and protection
Get-FileStatus -Path 'C:\9\SSL-RACIchart.xlsx' | Format-List *