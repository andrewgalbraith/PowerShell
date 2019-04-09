<#
.SYNOPSIS
  Applies the desired configuration to all resource mailboxes except those 
  defined in a control group
.DESCRIPTION
  The calendar settings of each resource mailbox that is not part of the 
  GRS_O365_Resource_Policy_Exclusions security group are assessed to determine 
  whether they match the desired configuration.

  The configuration is currently defined in the Set-ResourceDesiredConfiguration 
  function as a hashtable.
  
  This script accepts no parameters. If run on any host other than the current 
  automation server, a credential prompt is shown for connection to Exchange 
  Online. 
#>

# Connect to the Exchange Online service
Connect-ExchangeOnline

# Get a list of mailboxes excluded from the policy
$members = Get-DistributionGroupMember "GRS_O365_Resource_Policy_Exclusions" |
    Select-Object -ExpandProperty Name
Write-Output "Ignoring the following mailboxes, due to their membership of GRS_O365_Resource_Policy_Exclusions:"
Write-Output $members

# Get a list of resource mailboxes that aren't excluded form the resource policy
$rm = Get-Mailbox -RecipientTypeDetails RoomMailbox,EquipmentMailbox | 
    Where-Object { $_.Name -notin $members }

# Get the calendar processing settings of the mailboxes and for each of them
# verify that they match the desired configuration.
$rm | 
    Foreach-Object { 
        Write-Output "Mailbox name: $_"
        Write-Output "`tSetting calendar permissions"
        Set-ResourceCalendarPermissions $_; 
        Write-Output "`tUpdating calendar attendant settings"
        Set-ResourceDesiredConfiguration $_ 
    }

# Configure the resource mailboxes in the GRS_O365_RC_Mailboxes DL to process
# external meeting requests. Currently there is a transport rule that blocks
# all but the domain vendor.example.com from sending calendaring information.
Write-Output "Updating all members of GRS_O365_RC_Mailboxes so that they process external meeting requests."
Write-Output "NOTE: There is a transport rule configured to restrict the source of external meeting requests"
Get-DistributionGroupMember GRS_O365_RC_Mailboxes | 
    Where-Object { $_.RecipientTypeDetails -eq "RoomMailbox" } |
    Get-calendarProcessing |
    Where-Object { $_.ProcessExternalMeetingMessages -eq $false } |
    Set-CalendarProcessing -ProcessExternalMeetingMessages $true
