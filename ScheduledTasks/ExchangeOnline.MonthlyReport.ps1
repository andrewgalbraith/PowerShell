<#
.SYNOPSIS
    Builds a monthly mailbox / licence report in Excel and emails it.

.DESCRIPTION
    Joins Exchange Online mailbox data, MSOL licence data, recipient details and mailbox statistics into one
    row per mailbox, writes it to a styled Excel table via COM, and emails the workbook to a distribution list.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

# Return a collection with with the relevant information by combining info from the
# sources
function CombineInformation {
    param($Mailbox, $MSOLUser, $Recipient, $Statistics)
    Write-Debug "CombineInformation called with:"
    Write-Debug "$Mailbox, $MSOLUser, $Recipient, $Statistics"
   
    $license = $MSOLUser.Licenses[0]

    New-Object -TypeName PSCustomObject -Property @{
        FullName = $Mailbox.DisplayName
        UserID = $Mailbox.UserPrincipalName
        UserType = GetUserType $Mailbox.UserPrincipalName
        MailboxType = $Mailbox.RecipientTypeDetails
        Department = $MSOLUser.Department
        Office = $MSOLUser.Office
        Company = $Recipient.Company
        Country = $MSOLUser.Country
        LastLogin = (When-Falsy $Statistics.LastLogonTime -Return "Never").toString()
        DaysInactive = GetDaysInactive $Statistics.LastLogonTime $Mailbox.WhenMailboxCreated
        License = (When-Falsy (LicensePlanFromSku $license.AccountSkuID) -Return "None").toString()
        CreatedRecently = DateWithinLastXDays $Mailbox.WhenMailboxCreated 30
        Yammer = GetLicenseStatus "YAMMER_ENTERPRISE" $license
        RightsManagement = GetLicenseStatus "RMS_S_ENTERPRISE" $license
        OfficeProPlus =  GetLicenseStatus "OFFICESUBSCRIPTION" $license
        LyncOnline = GetLicenseStatus "MCOSTANDARD" $license
        OfficeWebApps = GetLicenseStatus "SHAREPOINTWAC" $license
        SharepointOnline = GetLicenseStatus "SHAREPOINTENTERPRISE" $license
        ExchangeEnterprise = GetLicenseStatus "EXCHANGE_S_ENTERPRISE" $license }
}



function GetLicenseStatus {
    param($Name, $License)
    $status = ($license.ServiceStatus | ? { $_.ServicePlan.ServiceName -eq $Name}).ProvisioningStatus
    (When-Falsy $status -Return "No").toString()
}

function When-Falsy {
    param($Expression, $Return)
    if($Expression) 
        { $Expression } 
    else 
        { $Return } 
}

function DateWithinLastXDays {
    param($date, $x)

    $date -ge (Get-Date).AddDays(-$x)
}

function GetDaysInactive {
    param($LogonTime, $Created)

    Write-Debug "GetDaysInactive called with the following arguments"
    Write-Debug "LogonTime - $LogonTime"
    Write-Debug "Created - $Created"

    if($LogonTime)
        { ((Get-Date) - (Get-Date $LogonTime)).Days }
    else
        { ((Get-Date) - (Get-Date $Created)).Days }
}

function GetUserType {
    param($ID)

    if($ID -match "^\w{2}\d{4,6}(@contoso\.com)$")
        { "Employee" }
    else 
        { "Generic" }
}


# Determine the licence plan based on the account SKU
function LicensePlanFromSKU {
    param([String]$sku)

    $plan = Get-Config -Scope Global | ? { $_.Name -like "Office365.Licensing.*" } |
        # Extract the SKU name from the license attribute
        ? { $_.Value -eq $sku.Split(":")[1] } |
        Select-Object @{Name="Key";Expression={($_.Key -split ".")[-1]}} | 
        Select-Object -Expand Key
    return $plan
}

# Connect to the various services which allow information to be gathered
Connect-ExchangeOnline
Connect-MSOL

# Retrieve all mailboxes from Exchange Online
$data = Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails UserMailbox,SharedMailbox,RoomMailbox,EquipmentMailbox |
    # Iterate over each mailbox, getting more information about each
    % { 
        Write-Debug "Combining information for Mailbox: $_"
        # Combines infromation about user and mailbox into a custom object for output
        CombineInformation -Mailbox $_ `
            -MSOLUser (Get-MSOLUser -UserPrincipalName $_.UserPrincipalName) `
            -Recipient (Get-Recipient -Identity $_.UserPrincipalName) `
            -Statistics (Get-MailboxStatistics -Identity $_.UserPrincipalName) 
     } | Select FullName,UserID,UserType,MailboxType,Company,Department,Office,Country,LastLogin,DaysInactive,CreatedRecently,License,OfficeProPlus,ExchangeEnterPrise,LyncOnline,RightsManagement,OfficeWebApps,SharepointOnline

# Export the data to a CSV file
$data | Export-CSV (Join-Path $PSScriptRoot "mailbox_report.csv") -NoTypeInformation -Force 

### Create an Excel object for the data ###
$Excel = New-Object -Com Excel.Application
# $Excel.Visible = $true
# Add a workbook to the Excel object
$Workbook = $Excel.Workbooks.Add()
# Set the title
$Workbook.Title = 'Mailbox report'
# Get the sheet from the workbook
$sheet = $Excel.Worksheets.Item(1)

### Populate the spreadsheet with data ###
# Create header array with headers in preferred order
$headers = @("FullName","UserID","UserType","MailboxType","Company","Department","Office","Country","LastLogin","DaysInactive","CreatedRecently","License","OfficeProPlus","ExchangeEnterPrise","LyncOnline","RightsManagement","OfficeWebApps","SharepointOnline")
# Get the number of headers for selecting the range in excel
$cols = $headers.Count
# Get the header range and populate it
$Range = $sheet.Range($sheet.Cells.Item(1,1), $sheet.Cells.Item(1,$cols))
$Range.Value2 = $headers
# Start a counter for row numbers
$counter = 2
# Add each mailbox to the sheet
$data | Foreach-Object {
    # Get an array of data from the object in the same order as the headers
    $item = $_
    $row = $headers | Foreach-Object {
        $item.$_
    }
    # Select the fange to fill based on the row counter and column count
    $Range = $sheet.Range($sheet.Cells.Item($counter,1), $sheet.Cells.Item($counter,$cols))
    Write-Debug $row[0]
    # Fill the row
    $Range.Value2 = $row
    # Increment the row counter
    $counter++
}

### Style the Sheet ###
# Set the name of the sheet
$sheet.Name = 'Mailbox report'
# Make the first row bold
$sheet.Rows.Item(1).Font.Bold = $true
# Freeze the top row?
# $sheet.Application.ActiveWindow.FreezePanes = $true
# Zoom to 75%
$sheet.Application.ActiveWindow.Zoom = 75
# Autofit columns
$sheet.UsedRange.EntireColumn.AutoFit()
# Set a table for the worksheet for sorting and filtering
$XlYesNoGuess = 'Microsoft.Office.Interop.Excel.XlYesNoGuess' -as [Type]
$ListObject = $sheet.ListObjects.Add(1,$sheet.UsedRange, $false, $XlYesNoGuess::xlNo)
# Set the table name
$ListObject.Name = "Table1"
# Set the table styly
$ListObject.TableStyle = "TableStyleMedium3"
# Enable filtering on the table
$ListObject.ShowAutoFilter = $true

### Save and email the workbook ###
$save_path = (Join-Path $PSScriptRoot "mailbox_report.xlsx")
$Workbook.SaveAs($save_path)
$Workbook.Close()
Send-MailMessage -Attachments $save_path -to DL_Office_365_Mailbox_Reports@contoso.com  -From (Get-ConfigItem Defaults.SMTP.FromAddress) -SmtpServer (Get-ConfigItem Defaults.SMTP.ServerAddress) -Subject "Latest Mailbox Report"
#Remove the sheet
Remove-Item $save_path
