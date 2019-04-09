<#
.SYNOPSIS
    Downloads the latest FEP/Defender definition packages through a proxy and emails a version summary.

.DESCRIPTION
    Downloads the latest FEP/Defender definition packages through a proxy and emails a version summary.

.NOTES
    Environment-specific values (domain, hostnames, share paths, mail addresses) have been
    replaced with placeholders such as contoso.com, AUTOMATION01 and smtp.contoso.com.
#>

#Downloading FEP definitions update from Microsoft Web pages
#Read this article http://technet.microsoft.com/en-us/library/gg398041.aspx
Clear-Host
$users = "it.admin@contoso.com", "it.admin2@contoso.com"
$server = "smtp.contoso.com"
$port = 25
$list = $args[0]
$to      = $user
$from    = "mailer@contoso.com"
$subject = "FEP definition Updates"
$output = "c:\temp\output.txt"
$dest = "D:\Fep_Updates"
$proxy = "10.0.0.1:8080"
Write-host "Definition updates downloaded:" > $output
echo "Definition updates downloaded by FILESERVER01:" > $output
echo "" >> $output
#Downloading updates

#------------------------------------
#mpam.fe.exe x64
#------------------------------------
$source = "http://go.microsoft.com/fwlink/?LinkID=121721&clcid=0x409&arch=x64"
$destination = $dest + "\x64\mpam-fe.exe"
$userAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2;)"
$WebClient = New-Object System.Net.WebClient
$WebProxy = New-Object System.Net.WebProxy($proxy,$false)
$WebClient.Headers.Add("user-agent", $userAgent)
$WebClient.Proxy = $WebProxy
$WebClient.DownloadFile("$source","$destination")
sleep 5
$ver1 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$destination").FileVersion
Write-Host "\x64\mpam-fe.exe ver: $ver1" >> $output
echo "\x64\mpam-fe.exe ver: $ver1" >> $output
$created1 = (get-item $destination).LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")
write-host "\x64\mpam-fe.exe Created: $created1" >> $output
echo "\x64\mpam-fe.exe Created: $created1" >> $output
echo "" >> $output
#------------------------------------

#------------------------------------
#mpam-d.exe x64
#------------------------------------
$source = "http://go.microsoft.com/fwlink/?LinkId=211054"
$destination = $dest + "\x64\mpam-d.exe"
$userAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2;)"
$WebClient = New-Object System.Net.WebClient
$WebProxy = New-Object System.Net.WebProxy($proxy,$false)
$WebClient.Headers.Add("user-agent", $userAgent)
$WebClient.Proxy = $WebProxy
$WebClient.DownloadFile("$source","$destination")
sleep 5
$ver2 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$destination").FileVersion
Write-Host "\x64\mpam-d.exe ver: $ver2" >> $output
echo "\x64\mpam-d.exe ver: $ver2" >> $output
$created2 = (get-item $destination).LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")
write-host "\x64\mpam-d.exe Created: $created2" >> $output
echo "\x64\mpam-d.exe Created: $created2" >> $output
echo "" >> $output
#------------------------------------

#------------------------------------
#nis_full.exe x64
#------------------------------------
$source = "http://go.microsoft.com/fwlink/?LinkId=197094"
$destination = $dest + "\x64\nis_full.exe"
$userAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2;)"
$WebClient = New-Object System.Net.WebClient
$WebProxy = New-Object System.Net.WebProxy($proxy,$false)
$WebClient.Headers.Add("user-agent", $userAgent)
$WebClient.Proxy = $WebProxy
$WebClient.DownloadFile("$source","$destination")
sleep 5
$ver3 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$destination").FileVersion
Write-Host "\x64\nis_full.exe ver: $ver3" >> $output
echo "\x64\nis_full.exe ver: $ver3" >> $output
$created3 = (get-item $destination).LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")
write-host "\x64\nis_full.exe Created: $created3" >> $output
echo "\x64\nis_full.exe Created: $created3" >> $output
echo "" >> $output
echo "" >> $output
#------------------------------------

# Completed x64 Downloads

#------------------------------------
#mpam-fe.exe x86
#------------------------------------
$source = "http://go.microsoft.com/fwlink/?LinkID=121721&clcid=0x409&arch=x86"
$destination = $dest + "\x86\mpam-fe.exe"
$userAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2;)"
$WebClient = New-Object System.Net.WebClient
$WebProxy = New-Object System.Net.WebProxy($proxy,$false)
$WebClient.Headers.Add("user-agent", $userAgent)
$WebClient.Proxy = $WebProxy
$WebClient.DownloadFile("$source","$destination")
sleep 5
$ver4 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$destination").FileVersion
Write-Host "\x86\mpam-fe.exe ver: $ver4" >> $output
echo "\x86\mpam-fe.exe ver: $ver4" >> $output
$created4 = (get-item $destination).LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")
write-host "\x86\mpam-fe.exe Created: $created4" >> $output
echo "\x86\mpam-fe.exe Created: $created4" >> $output
echo "" >> $output
#------------------------------------

#------------------------------------
#mpam-d.exe x86
#------------------------------------
#------------------------------------
$source = "http://go.microsoft.com/fwlink/?LinkId=211053"
$destination = $dest + "\x86\mpam-d.exe"
$userAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2;)"
$WebClient = New-Object System.Net.WebClient
$WebProxy = New-Object System.Net.WebProxy($proxy,$false)
$WebClient.Headers.Add("user-agent", $userAgent)
$WebClient.Proxy = $WebProxy
$WebClient.DownloadFile("$source","$destination")
sleep 5
$ver5 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$destination").FileVersion
Write-Host "\x86\mpam-d.exe ver: $ver5" >> $output
echo "\x86\mpam-d.exe ver: $ver5" >> $output
$created5 = (get-item $destination).LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")
write-host "\x86\mpam-d.exe Created: $created5" >> $output
echo "\x86\mpam-d.exe Created: $created5" >> $output
echo "" >> $output
#------------------------------------

#------------------------------------
#nis_full.exe x86
#------------------------------------
$source = "http://go.microsoft.com/fwlink/?LinkId=197095"
$destination = $dest + "\x86\nis_full.exe"
$userAgent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.2;)"
$WebClient = New-Object System.Net.WebClient
$WebProxy = New-Object System.Net.WebProxy($proxy,$false)
$WebClient.Headers.Add("user-agent", $userAgent)
$WebClient.Proxy = $WebProxy
$WebClient.DownloadFile("$source","$destination")
sleep 5
$ver6 = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$destination").FileVersion
Write-Host "\x86\nis_full.exe ver: $ver6" >> $output
echo "\x86\nis_full.exe ver: $ver6" >> $output
$created6 = (get-item $destination).LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")
write-host "\x86\nis_full.exe Created: $created6" >> $output
echo "\x86\nis_full.exe Created: $created6" >> $output
echo "" >> $output
#------------------------------------

#------------------------------------
# Comparing File Versions
#------------------------------------
#
#if (($ver1 -ne $ver2) -or ($ver4 -ne $ver5) -or ($ver1 -ne $ver4))
#{
#	cmd.exe /c c:\FEP_FILES\defupdates\defupdate.bat
#	exit
#	}
#elseif
#
#------------------------------------
# Downloads Complete.  Generating Current Version
#------------------------------------
#$url = "https://www.microsoft.com/security/portal/definitions/whatsnew.aspx"
#$webclient = new-object System.Net.WebClient
#$WebProxy = New-Object System.Net.WebProxy($proxy,$false)
#$WebClient.Headers.Add("user-agent", $userAgent)
#$WebClient.Proxy = $WebProxy
#$webpage = $webclient.DownloadString($url)
#$webpage2 = $webpage
#$webpagetxt = "C:\FEP_Files\VersionOutput\webpage.txt"

#sleep 5
 
# Parse web page and find Current Version.
#$pattern = Select-String "$webpage" -pattern '<span id="ctl00_ctl00_pageContent_leftside_ActiveVersionLabel" style="margin-right: 8px;">'
#$pattern = $pattern.get_Line() -replace "\s",""
#$current = $pattern.TrimStart('<span id="ctl00_ctl00_pageContent_leftside_ActiveVersionLabel" style="margin-right: 8px;">')
#$current = $current.SubString(0,12)
#$current > $webpagetxt

# Show Current Version
#Write-Host "Current Version: $current" >> $output
#echo "Current Version: $current" >> $output

# Parse web page and find Current Version release date and time.
#$pattern2 = Select-String "$webpage2" -pattern 'Definition available date: </span><br />'
#$pattern2 = $pattern2.get_Line() -replace "\s",""
#$current2 = $pattern2.TrimStart('Definition available date: </span><br />')
#$current2 = $current2.SubString(0,25)
#$current2 > $webpagetxt2
 
# Show Current Version
#Write-Host "Current Version Release Date: $current2" >> $output
#echo "Current Version Release Date: $current2" >> $output

#rename-item c:\fep_files\versionoutput\webpage.txt "fepversion $(get-date -f yyyyMMddHHmm).txt"

#------------------------------------
# Complete.  Now Sending Email
#------------------------------------

foreach ($user in $users)
{
 
$to      = $user
 
$from    = "mailer@contoso.com"
 
$subject = "FEP definition Updates"
 
#foreach ($line in Get-Content $output)
 foreach ($line in Get-Content $output)
{
 
$body += “$line `n”
 
} 
# Create mail message
 
$message = New-Object system.net.mail.MailMessage $from, $to, $subject, $body
 
#Create SMTP client
 
$client = New-Object system.Net.Mail.SmtpClient $server, $port
 
# Credentials are necessary if the server requires the client # to authenticate before it will send e-mail on the client's behalf.
 
$client.Credentials = [system.Net.CredentialCache]::DefaultNetworkCredentials
 
# Try to send the message
 
try {      
 
$client.Send($message)      
 
"Message sent successfully"
 
# reset variables
 
$body = ""
 
}
 
# Catch an error
 
catch {
 
"Exception caught in CreateTestMessage1(): "
 
}
 
}

# End of Script
