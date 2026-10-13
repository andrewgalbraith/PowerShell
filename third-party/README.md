# Third-party scripts

Community scripts I used or adapted on the job, kept here so they stay with the rest of the
toolkit. They are **not my work** — original author headers are preserved where they existed.
Environment-specific values were replaced with placeholders like everything else in this repo.

| Script | Author | What it does |
|---|---|---|
| `Check-WannaCryPatches.ps1` | Kieran Walsh (Computer Talk Ltd) | Checks a list of servers for the MS17-010 / WannaCry patches and logs who is unpatched. |
| `ConnectExchangeOnlinePowerShell.ps1` | o365reports.com | Connect to Exchange Online PowerShell with or without MFA (pre-EXO V2 module). |
| `Export_AD_Users_to_CSV.ps1` | Victor Ashiedu | Export AD users to CSV. |
| `Get-LockedOutLocation.ps1` | Jason Walker | Find which computer an account lockout came from. |
| `WakeOnLAN.ps1` | Matthijs ten Seldam (Microsoft) | Send a Wake-on-LAN magic packet. |
| `cleanup-disk-install.ps1` | Tom Moser (Microsoft PFE) | Installs the Disk Cleanup tool on Windows Server. |
| `getFolderSize.ps1` | Martin Pugh | Fast folder-size report using robocopy. |
| `Get-WindowsVersion.ps1` | dertechblog.de | Reports Windows version / build for local, remote or AD-scoped computers. |
| `Get-ADUserLockouts.ps1` | origin unknown (adapted) | Pulls 4740 lockout events from the PDC emulator, optionally per user. |
| `HyperVReport.ps1` | Serhat Akinci (serhatakinci.com) | Hyper-V cluster/host HTML reporting script; called by ScheduledTasks/StorageManagement.Hyper-VReport.ps1. |

Bundled community functions also live inside `Modules/Utils/functions/` (e.g. `Get-RemoteProgram` by
Jaap Brasser, `Get-FolderItem` by Boe Prox, `Get-PendingReboot` by Brian Wilhite) — each keeps its own header.
