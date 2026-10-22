# Define the path to the input text file and output CSV file
$InputFile = "C:\temp\mkssapusers.txt"
$OutputFile = "C:\temp\mksndessapusers.csv"

# Read the list of usernames from the text file
$UserNames = Get-Content -Path $InputFile

# Initialize an empty array to store user information
$UserDetails = @()

# Loop through each username and fetch specified attributes
foreach ($UserName in $UserNames) {
    # Get user details from Active Directory
    $User = Get-ADUser -Identity $UserName -Properties l, physicalDeliveryOfficeName
    
    # Create a custom object with the required attributes
    $UserDetails += [PSCustomObject]@{
        SamAccountName = $User.SamAccountName
        l     = $User.l
        physicalDeliveryOfficeName     = $User.physicalDeliveryOfficeName
    }
}

# Export the results to a CSV file
$UserDetails | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8

Write-Host "User attributes exported to $OutputFile"
