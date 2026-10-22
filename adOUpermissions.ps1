# Import ActiveDirectory module
Import-Module ActiveDirectory

# Specify the distinguished name (DN) of the OU you want to check
$ouDN = "DC=mksinternal,DC=com"

# Get the ACL of the OU
$acl = Get-Acl -path "AD:$ouDN"

# Initialize an empty array to store results
$results = @()

# Loop through each Access Rule in the ACL
foreach ($accessRule in $acl.Access) {
    # Check if the Access Rule applies to a user or group
    if ($accessRule.IdentityReference -like "CN=*") {
        # Get the user or group name
        $name = $accessRule.IdentityReference.ToString()
        
        # Get the access rights
        $rights = $accessRule.FileSystemRights.ToString()
        
        # Create a custom object to store the results
        $result = [PSCustomObject]@{
            'OU'     = $ouDN
            'User/Group' = $name
            'Permissions' = $rights
        }
        
        # Add the result to the results array
        $results += $result
    }
}

# Display the results
$results | Format-Table -AutoSize
