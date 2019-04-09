<# 
.SYNOPSIS
    Disable any enabled computer accounts that have been inactive for longer
    than 3 months
.DESCRIPTION
    Queries AD for computer accounts that have had no login activity in the 
    last 3 months, which are also enalbed, then disables them. Also updates
    the account description with the date that the account was disabled.
#>

# Get the date 3 months ago and convert to file time
$3_months_ago = (Get-Date).AddMonths(-3).ToFileTime()

# Get today's date for the computer description
$date = (Get-Date).toString("dd/MM/yy")

# Create a filter that for machines that have not logged on for 3 months
$filter = "(-not (useraccountcontrol -band 2)) -and (LastLogonTimestamp -lt '$3_months_ago')"

# Get the compusters that match the filter
Get-ADCOmputer -Filter $filter -Properties LastLogonTimestamp, Description |

    ForEach-Object {

        # Disable the computer
        Write-Verbose "Disabling $($_.Name)"
        Disable-ADAccount -Identity $_.DistinguishedName

        # Prepend the current description with disabled message
        $new_desc = "[$date : automatically disabled due to inactivity] " +
            $_.Description

        # Set the description
        Write-Verbose "Setting $($_.Name) description to `"$new_desc`""
        Set-ADComputer -Identity $_.DistinguishedName -Description $new_desc

    }
