<#
.SYNOPSIS
    Keeps AD group membership in sync with an LDAP filter per group.

.DESCRIPTION
    Reads a group -> filter map from config, compares the objects matching each filter with the group's
    current members, and adds or removes members so the group always reflects the filter.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

$map = Get-ConfigItem ActiveDirectory.DynamicGroupMembershipMap

$map.Keys |
    Foreach-Object {                
        # Save the group name for later use
        $groupName = $_
        
        # Output notification that group is being processed
        Write-Host "--- PROCESSING GROUP: " $groupName " ---"

        # Get the list of objects that match the current filter
        $filterMatch = @(Get-ADObject -Filter $map[$groupName] | Select -ExpandProperty DistinguishedName)
        
        # Get the list of objects currently in the group
        $currentList = @(Get-ADGroup $_ -Properties Member | Select -ExpandProperty Member)

        # Compare the list of objects
        Compare-Object -ReferenceObject $currentList -DifferenceObject $filterMatch |

            # Iterate over each anomaly
            Foreach-Object {
            
                # Either add or remove it depending on the SideIndicator property of the comparison
                if ($_.SideIndicator -eq "=>")
                {
                    # Display notification of addition
                    Write-Host "Adding: " $_.InputObject

                    # Add the user to the group
                    Add-ADGroupMember -Identity $groupName -Members $_.InputObject -Confirm:$false
                }

                else
                {
                    # Display removal notification
                    Write-Host "Removing: " $_.InputObject

                    # Remove the user from the group
                    Remove-ADGroupMember -Identity $groupName -Members $_.InputObject -Confirm:$false
                }

            }
    }
