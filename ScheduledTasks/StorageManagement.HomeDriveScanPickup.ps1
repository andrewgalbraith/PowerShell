<#
.SYNOPSIS
    Check pickup folder for OneDrive scan requests
.DESCRIPTION
    Checks pickup folder for OneDrive scan requests and initiates 
    them one-by-one. Once the scan has completed the file is removed. The file
    is expected to be named with the user's samAccountName, without an
    extension.
#>
Get-ChildItem "\\AUTOMATION01\drop\onedrive-scan" | ForEach-Object {
    
    # Get the user's home drive path to save output files to.
    $EmailAddress = Get-ADUser $_.BaseName -Properties Mail |
        Select-Object -ExpandProperty Mail

    if($EmailAddress) {

        # Create a temporary folder for the scan output
        $loc = "C:\TEMP\" + $_.BaseName
        if(-not (Test-Path $loc)) {
            New-Item -Path $loc -ItemType Directory
        }
        
        # Initiate the scan
        $_.BaseName | 
        Start-FolderItemSummaryScan -OutputFolder $loc `
            -IncludeRedirected

        if(Test-Path (Join-Path $loc "summary.csv")) {
            # Get the results files.
            $att = Get-ChildItem -Path $loc -Filter "*.csv" |
                Select-Object -ExpandProperty FullName
            # Email the results
            Send-MailMessage -To $EmailAddress `
                -Attachments $att `
                -From helpdesk@contoso.com `
                -SmtpServer smtp.contoso.com `
                -Subject "OneDrive readiness scan results"
                -Body "Please find attached the results of your OneDrive scan request"
        }       

        # Remove the drop file
        Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        
        # Remove the temporary file location
        Remove-Item $loc -Recurse -Force
    }
}
