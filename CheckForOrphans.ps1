Import-Module LithnetMIISAutomation

# Get the management agents for Management Agent 1 and Management Agent 2
$ma1 = Get-ManagementAgent -Name "mksinternal.com"
$ma2 = Get-ManagementAgent -Name "newport.com"

# Get all metaverse objects

$mvQuery = New-MVQuery -Attribute csObjectID -Operator IsPresent;
$metaverseObjects = Get-MVObject -Queries $mvQuery -ObjectType Person | ?{($_.Attributes.keys -contains 'employeeID') -and (($_.Attributes.employeeStatus.Values.ValueString | select -First 1) -like 'A')}
$reportData = @()
# Initialize an array to store the report data
foreach ($mvObject in $metaverseObjects) {

    # Get the csmvlinks property of the Metaverse object
    $csmvlinks = $mvObject.csmvlinks

    # Check if the Metaverse object is linked to either Management Agent 1 or Management Agent 2
    $linkedToMA1 = $false
    $linkedToMA2 = $false

    foreach ($link in $csmvlinks) {
        if ($link.ManagementAgentName -eq "mksinternal.com") {
            $linkedToMA1 = $true
        } elseif ($link.ManagementAgentName -eq "newport.com") {
            $linkedToMA2 = $true
        }
    }

    # If the Metaverse object is not linked to either Management Agent 1 or Management Agent 2
    if (-not $linkedToMA1 -and -not $linkedToMA2) {

        Write-Host "Metaverse object $($mvObject.ObjectID) is orphaned and not tied to Active Directory."

        # Add the Metaverse object attributes to the report data array
        $reportData += [PSCustomObject]@{
            'ObjectID' = $mvObject.Attributes.csObjectID.Values.ValueString | select -First 1
            'Orphaned' = $true
            'accountName' = $mvObject.Attributes.accountName.Values.ValueString | select -First 1
            'employeeID' = $mvObject.Attributes.employeeID.Values.ValueString | select -First 1
            'employeeStatus' = $mvObject.Attributes.employeeStatus.Values.ValueString | select -First 1
            'employeeType' = $mvObject.Attributes.employeeType.Values.ValueString | select -First 1
            'employmentType' = $mvObject.Attributes.employmentType.Values.ValueString | select -First 1
            'PreferredFirstName' = $mvObject.Attributes.PreferredFistName.Values.ValueString | select -First 1
            'lastName' = $mvObject.Attributes.lastName.Values.ValueString | select -First 1
        }
    }
}

# Export the report data to a CSV file
$reportData | Export-Csv -Path "C:\scripts\Remediation23\OrphanReport4-19.csv" -NoTypeInformation