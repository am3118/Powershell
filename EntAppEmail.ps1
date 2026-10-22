$application = Get-AzureADApplication -Filter "DisplayName eq 'WD - Production'"

# Check if application exists
if ($application -eq $null) {
    Write-Host "Application not found"
} else {
    # Get notification emails for the application
    $notificationEmails = $application.NotificationEmailAddresses

    # Check if notification emails exist
    if ($notificationEmails.Count -eq 0) {
        Write-Host "No notification emails found for the application"
    } else {
        Write-Host "Notification emails for the application:"
        foreach ($email in $notificationEmails) {
            Write-Host $email
        }
    }
}