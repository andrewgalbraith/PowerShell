<#
.SYNOPSIS
    Swaps lync.exe on a list of remote PCs, tracking which ones are done.

.DESCRIPTION
    Pings each computer from a text file, renames the existing lync.exe to .old over the
    admin share, copies the replacement in, logs the completed machines and removes
    them from the input list so the script can be re-run until every PC is covered.

.NOTES
    Domain names, hostnames, IPs and file paths in this script were replaced with
    placeholders (contoso.com, $env:USERPROFILE, etc.) before publishing. Adjust for your environment.
#>

$listpath = "C:\Powershell\Kill_Skype\americas_Desktop_PCs.txt"
$filepath = "C:\Program Files (x86)\Microsoft Office\root\Office16\lync.exe"
$logfile = "C:\Powershell\Kill_Skype\done.txt"
$file = Get-ChildItem $filepath
[System.Collections.ArrayList]$list = @(Get-content $listpath)
[System.Collections.ArrayList]$done = @()

foreach($ComputerName in $list){
  if(Test-Connection -ComputerName $ComputerName -Count 1 -Quiet){
    if(Test-Path "\\$($ComputerName)\C$\Program Files (x86)\Microsoft Office\root\Office16\lync.exe"){
      if(Test-Path "\\$($ComputerName)\C$\Program Files (x86)\Microsoft Office\root\Office16\lync.exe.old"){
        "lync.old already exists on $($ComputerName)"
      }
      else{
        "Processing $($ComputerName)"
        rename-item "\\$($ComputerName)\C$\Program Files (x86)\Microsoft Office\root\Office16\lync.exe" -NewName lync.exe.old
        copy-item $file "\\$($ComputerName)\C$\Program Files (x86)\Microsoft Office\root\Office16\"
        $done.Add($ComputerName) | Out-Null
      }
    }
    else{
      "lync.exe path not found on $($ComputerName)"
    }
  }
  else{
    "Can't connect to $($ComputerName)"
  }
}

Add-Content $done -Path $logfile
$done | foreach{$list.Remove($_)}
Set-Content -Path $listpath -Value $list
