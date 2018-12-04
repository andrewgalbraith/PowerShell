<#
.SYNOPSIS
Returns Password information for target user.
.DESCRIPTION
Lists the users user ID to check you have the right user. Also lists whether the password is expired right now (Boolean value), when the password was last set, and if the password is set to never expire (Boolean Value). Password expiry date is not a retrievable value from Active Directory. Requires the NAME of the user.
#>

$maxPasswordAge = (get-addefaultdomainpasswordpolicy).MaxPasswordAge.Days

	[string]$targetuser = read-host "Please specify a user's name."
	write-host "Connecting to Active Directory."
	if ($targetuser -eq "") 
	{
	write-warning "D'oh. You forgot to enter a user"
	}
	else
	{
    $usercheck = get-aduser -filter 'name -eq $targetuser'
	if ($usercheck -eq $null)
  {
    write-warning -message "Specified user does not exist."
  }
    else
  {
    get-aduser -filter 'name -eq $targetuser' -properties Passwordexpired,passwordlastset,passwordneverexpires | select samaccountname,Passwordexpired,passwordlastset,passwordneverexpires,@{l="ExpiryDate";e={$_.PasswordLastSet.AddDays($maxPasswordAge)}} | format-list
  }
}
