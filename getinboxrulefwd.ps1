$UPN = "goektuerk.simsekol@mksinst.com"

Get-InboxRule -Mailbox $UPN -IncludeHidden |
    Where-Object {
        $_.ForwardTo -or
        $_.ForwardAsAttachmentTo -or
        $_.RedirectTo
    } |
    Select-Object Name, Enabled, Priority, Description,
        ForwardTo, ForwardAsAttachmentTo, RedirectTo |
    Format-List