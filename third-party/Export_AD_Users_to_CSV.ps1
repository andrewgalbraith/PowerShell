###########################################################
# AUTHOR  : Victor Ashiedu
# WEBSITE : iTechguides.com
# BLOG    : iTechguides.com/blog-2/
# CREATED : 08-08-2014 
# UPDATED : 19-09-2014 
# COMMENT : This script exports Active Directory users
#           to a a csv file. v2.1 adds the condition to 
#           ignore all users with the info (Notes) field
#           found on the Telephones tab containing the 
#           word 'Migrated'. 
###########################################################


#Define location of my script variable
#the -parent switch returns one directory lower from directory defined. 
#below will return up to ImportADUsers folder 
#and since my files are located here it will find it.
#It failes withpout appending "*.*" at the end

$path = Split-Path -parent "C:\PowerShell\Test\"

#Create a variable for the date stamp in the log file

$LogDate = get-date -f yyyyMMddhhmm

#Define CSV and log file location variables
#they have to be on the same location as the script

$csvfile = $path + "\ADManagers_$logDate.csv"

#import the ActiveDirectory Module

Import-Module ActiveDirectory


#Sets the OU to do the base search for all user accounts, change as required.
#Simon discovered that some users were missing
#I decided to run the report from the root of the domain

#$SearchBase = "OU=US (Contoso Inc)" #May need these OU=Accounts (Users),OU=Operations,DC=contoso,DC=com

#Get Admin accountb credential

$GetAdminact = Get-Credential

#Define variable for a server with AD web services installed

$ADServer = 'DC01.contoso.com'

#Find users that are not disabled
#To test, I moved the following users to the OU=ADMigration:
#Philip Steventon (kingston.gov.uk/RBK Users/ICT Staff/Philip Steventon) - Disabled account
#Joseph Martins (kingston.gov.uk/RBK Users/ICT Staff/Joseph Martins) - Disabled account
#may have to get accountb status with another AD object

#Define "Account Status" 
#Added the Where-Object clause on 23/07/2014
#Requested by the project team. This 'flag field' needs
#updated in the import script when users fields are updated
#The word 'Migrated' is added in the Notes field, on the Telephone tab.
#The LDAB object name for Notes is 'info'. 

$AllADUsers = Get-ADUser -SearchBase "OU=US (Contoso ACE),OU=Accounts (Users),OU=Operations,DC=contoso,DC=com" -Properties * -Filter * #? { ($_.distinguishedname -notlike '*Disabled Users*') } #-Filter * -Properties DisplayName,PostalCode #Etc.
#-Credential $GetAdminact -searchbase $SearchBase `
#-Filter * -Properties * | Where-Object {$_.info -NE 'Migrated'} #ensures that updated users are never exported.

$AllADUsers |
Select-Object @{Label = "FIRSTNAME";Expression = {$_.GivenName}},
@{Label = "LASTNAME";Expression = {$_.Surname}},
#@{Label = "Display Name";Expression = {$_.displayName}},
#@{Label = "Logon Name";Expression = {$_.sAMAccountName}},
#@{Label = "Phone";Expression = {$_.telephoneNumber}},
@{Label = "EMAIL";Expression = {$_.EmailAddress}},
@{Label='MGR';Expression = {%{(Get-AdUser $_.Manager -server $ADServer -Properties DisplayName).DisplayName}}} |
#@{label='Manager';expression={$_.manager -replace '^CN=|,.*$'}} |
#@{Label = "Manager";Expression = {%{(Get-AdUser $_.Manager -server $ADServer -Properties DisplayName).DisplayName}}} |

#Export CSV report

Export-Csv -Path $csvfile
