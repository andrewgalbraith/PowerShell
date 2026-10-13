# PowerShell

PowerShell I wrote as a Windows systems administrator / automation engineer: Active Directory
and Exchange Online automation, a small workflow engine for user provisioning, storage and
Hyper-V housekeeping, and a menu-driven console for the service desk.

Everything here ran in a real enterprise. Before publishing, every identifying detail was
replaced with a placeholder — `contoso.com` for the domain, `AUTOMATION01` / `FILER01` /
`CLUSTER01` for hosts, `smtp.contoso.com` for mail relay, `it.admin@contoso.com` for people,
`$env:USERPROFILE` for hard-coded profile paths. Logic is unchanged.

**About the history:** this repo was imported from my working folder in October 2026. Each commit
carries the original last-modified date of the files it adds, so the timeline reflects when the work
was done (2017–2021) rather than when it was published. The 31 scheduled tasks share one date because
that is the day they were installed from the internal feed, not the day each was written.

## Layout

| Folder | Contents |
|---|---|
| [`Modules/`](Modules) | Five modules that formed the team's shared PowerShell environment (see below) |
| [`ScheduledTasks/`](ScheduledTasks) | 31 jobs that ran unattended on an automation host — AD hygiene, Exchange Online policy, storage clean-up, reporting |
| [`ActiveDirectory/`](ActiveDirectory), [`Endpoint/`](Endpoint), [`Reporting/`](Reporting) | Ad-hoc admin scripts from day-to-day work |
| [`Profile/`](Profile) | The shared profile that bootstrapped the environment and kept modules up to date from an internal PSGallery feed |
| [`third-party/`](third-party) | Community scripts I used on the job — **not my work**, kept with attribution |

## Modules

| Module | What it does |
|---|---|
| [`Automation`](Modules/Automation) | A file-backed **workflow engine**: each workflow (new user with mailbox, new shared/resource mailbox, leaver, licence upgrade) is a class whose instances are serialised to XML, picked up by a scheduled coordinator, locked, advanced one state at a time, and archived on completion. Transcripts of every run are emailed. |
| [`Config`](Modules/Config) | Layered configuration store (script → user → global) backed by CliXml files on a share, so scripts never hard-code environment values. `Get-ConfigItem` / `Set-ConfigItem` are used throughout. |
| [`Office365`](Modules/Office365) | Session helpers for Exchange Online, hybrid Exchange, MSOL, SharePoint Online and Skype for Business, plus mailbox/licensing operations (convert to shared, migrate, resource-mailbox policy, licence-by-group). |
| [`Utils`](Modules/Utils) | Grab-bag of functions: AD lockout investigation, NPS/ADFS login searches, DFS path resolution, folder ownership/ACL repair, OneDrive-readiness scanning, managed service accounts, task-script scaffolding. |
| [`Menu`](Modules/Menu) | A folder-driven console menu: every sub-folder under `Main/` is a sub-menu and every `.ps1` is an action whose `.SYNOPSIS` becomes the menu text. Used by the service desk to run approved scripts without touching PowerShell. |

## Scheduled tasks

| Script | What it does |
|---|---|
| [`ActiveDirectory.AccountLockoutAnalysis.ps1`](ScheduledTasks/ActiveDirectory.AccountLockoutAnalysis.ps1) | Investigates AD account lockouts and emails the helpdesk a report per lockout. |
| [`ActiveDirectory.CRMGASImport.ps1`](ScheduledTasks/ActiveDirectory.CRMGASImport.ps1) | Adds users exported by regional CRM servers to matching AD groups. |
| [`ActiveDirectory.DisableInactiveComputers.ps1`](ScheduledTasks/ActiveDirectory.DisableInactiveComputers.ps1) | Disables computer accounts with no logon activity in 3 months. |
| [`ActiveDirectory.DynamicGroupMembership.ps1`](ScheduledTasks/ActiveDirectory.DynamicGroupMembership.ps1) | Keeps AD group membership in sync with an LDAP filter per group. |
| [`Automation.ProcessWorkflows.ps1`](ScheduledTasks/Automation.ProcessWorkflows.ps1) | Scheduled entry point that runs pending workflow instances. |
| [`Automation.RemoveOldTranscripts.ps1`](ScheduledTasks/Automation.RemoveOldTranscripts.ps1) | Deletes automation transcripts older than one month. |
| [`Automation.UnstickWorkflows.ps1`](ScheduledTasks/Automation.UnstickWorkflows.ps1) | Clears a stale workflow lock file. |
| [`DFS.GlobalNamespace.Export.ps1`](ScheduledTasks/DFS.GlobalNamespace.Export.ps1) | Exports the DFS namespace to XML as a recoverable backup. |
| [`ExchangeOnline.ActivateOnlineArchive.ps1`](ScheduledTasks/ExchangeOnline.ActivateOnlineArchive.ps1) | Enables an Online Archive for migrated mailboxes that don't have one. |
| [`ExchangeOnline.ActiveSyncGroupMembership.ps1`](ScheduledTasks/ExchangeOnline.ActiveSyncGroupMembership.ps1) | Enforces ActiveSync on/off based on membership of an allow-list group. |
| [`ExchangeOnline.DeletedItemsRetention.ps1`](ScheduledTasks/ExchangeOnline.DeletedItemsRetention.ps1) | Sets a 30-day Deleted Items retention on every user mailbox. |
| [`ExchangeOnline.MailboxAdminAuditing.ps1`](ScheduledTasks/ExchangeOnline.MailboxAdminAuditing.ps1) | Turns on mailbox auditing with a standard action set for every unaudited mailbox. |
| [`ExchangeOnline.MonthlyReport.ps1`](ScheduledTasks/ExchangeOnline.MonthlyReport.ps1) | Builds a monthly mailbox / licence report in Excel and emails it. |
| [`ExchangeOnline.ResourceMailboxConfiguration.ps1`](ScheduledTasks/ExchangeOnline.ResourceMailboxConfiguration.ps1) | Applies a standard calendar-processing configuration to room and equipment mailboxes. |
| [`ExchangeOnline.UpdateUserPhotos.ps1`](ScheduledTasks/ExchangeOnline.UpdateUserPhotos.ps1) | Pushes new HR photo exports to Office 365 and on-premises AD. |
| [`LocateIncompatiblePaths.ps1`](ScheduledTasks/LocateIncompatiblePaths.ps1) | Finds paths too long for Windows Explorer and exports them to CSV. |
| [`MicrosoftOnline.UpdateFederatedDomain.ps1`](ScheduledTasks/MicrosoftOnline.UpdateFederatedDomain.ps1) | Refreshes the federated domain configuration against the ADFS server. |
| [`StorageManagement.Top100Profiles.ps1`](ScheduledTasks/StorageManagement.Top100Profiles.ps1) | Lists the largest roaming-profile folders on the profile share. |
| [`StorageManagement.HomeDriveRemoval.ps1`](ScheduledTasks/StorageManagement.HomeDriveRemoval.ps1) | Finds and removes home folders that no longer belong to an AD user. |
| [`StorageManagement.HomeDriveScanPickup.ps1`](ScheduledTasks/StorageManagement.HomeDriveScanPickup.ps1) | Processes OneDrive-readiness scan requests dropped in a pickup folder. |
| [`StorageManagement.Hyper-VReport.ps1`](ScheduledTasks/StorageManagement.Hyper-VReport.ps1) | Runs the Hyper-V report against each cluster and host and emails the results. |
| [`StorageManagement.ProfileFolderRemoval.ps1`](ScheduledTasks/StorageManagement.ProfileFolderRemoval.ps1) | Removes roaming profile folders unused for 3 months. |
| [`StorageManagement.RedirectedMyDocumentsRemoval.ps1`](ScheduledTasks/StorageManagement.RedirectedMyDocumentsRemoval.ps1) | Removes redirected My Documents folders for users that no longer exist. |
| [`StorageManagement.SnapshotCleardown.ps1`](ScheduledTasks/StorageManagement.SnapshotCleardown.ps1) | Deletes VSS shadow copies on all Hyper-V hosts at a site. |
| [`StorageManagement.SupportReport.ps1`](ScheduledTasks/StorageManagement.SupportReport.ps1) | Builds a tabbed HTML dashboard of NetApp volumes, SnapMirror and Hyper-V cluster health. |
| [`StorageManagement.TransferDriveCleanup.ps1`](ScheduledTasks/StorageManagement.TransferDriveCleanup.ps1) | Purges anything older than 30 days from the shared transfer folders. |
| [`System.AutomationUserLoginCheck.ps1`](ScheduledTasks/System.AutomationUserLoginCheck.ps1) | Emails an alert if the automation service account is not logged on to the automation host. |
| [`UserManagement.Leavers.ps1`](ScheduledTasks/UserManagement.Leavers.ps1) | Automates the leaver process: manager access, notification email, and deletion after retention. |
| [`VirtualisationManagement.MTPLibraryRefresh.ps1`](ScheduledTasks/VirtualisationManagement.MTPLibraryRefresh.ps1) | Triggers a refresh of an SCVMM library share. |
| [`VirtualisationManagement.SCVMMIPRelease.ps1`](ScheduledTasks/VirtualisationManagement.SCVMMIPRelease.ps1) | Returns unassigned SCVMM IP addresses to the pool. |
| [`WindowsDefender.DefUpdate.ps1`](ScheduledTasks/WindowsDefender.DefUpdate.ps1) | Downloads the latest FEP/Defender definition packages through a proxy and emails a version summary. |

## Ad-hoc scripts

### ActiveDirectory

| Script | What it does |
|---|---|
| [`Find-ComputersNotInGroup.ps1`](ActiveDirectory/Find-ComputersNotInGroup.ps1) | Finds enabled computer objects in an OU that are NOT members of a given security group. |
| [`Find-OrphanedUserFolders.ps1`](ActiveDirectory/Find-OrphanedUserFolders.ps1) | Checks which home-folder names on a file share no longer match an AD account. |
| [`Find-UsersFromCsv.ps1`](ActiveDirectory/Find-UsersFromCsv.ps1) | Looks up AD users from a CSV of first name / last name / username. |
| [`Get-GroupMembersByRegion.ps1`](ActiveDirectory/Get-GroupMembersByRegion.ps1) | Lists members of an AD group, filtered to users whose Office is in the Americas. |
| [`Get-GroupMembersReport.ps1`](ActiveDirectory/Get-GroupMembersReport.ps1) | Exports a recursive membership report for an AD group to CSV. |
| [`Get-GroupsInOU.ps1`](ActiveDirectory/Get-GroupsInOU.ps1) | Prints every group under a search base along with its members. |
| [`Get-LastLogonForComputersNotInGroup.ps1`](ActiveDirectory/Get-LastLogonForComputersNotInGroup.ps1) | Finds computers missing from a security group, then pulls the last interactive logon for each. |
| [`Get-UsersWithManagers.ps1`](ActiveDirectory/Get-UsersWithManagers.ps1) | Exports every user in an OU with their department and manager's display name. |

### Endpoint

| Script | What it does |
|---|---|
| [`Get-ClusterSharedVolumeSpace.ps1`](Endpoint/Get-ClusterSharedVolumeSpace.ps1) | Reports size, free and used space for every Cluster Shared Volume on a failover cluster. |
| [`Get-LastLogonAndUser.ps1`](Endpoint/Get-LastLogonAndUser.ps1) | For each AD computer matching a name pattern, reports last logon time and the current user. |
| [`Get-LoggedInUser.ps1`](Endpoint/Get-LoggedInUser.ps1) | Returns the user currently logged on to a remote computer. |
| [`Get-MostFrequentUser.ps1`](Endpoint/Get-MostFrequentUser.ps1) | Returns the user who has logged on most often in the last N Winlogon events. |
| [`Get-RemoteSerialNumber.ps1`](Endpoint/Get-RemoteSerialNumber.ps1) | Grabs a remote machine's BIOS serial number and its last privileged logon. |
| [`Replace-LyncOnRemotePCs.ps1`](Endpoint/Replace-LyncOnRemotePCs.ps1) | Swaps lync.exe on a list of remote PCs, tracking which ones are done. |

### Reporting

| Script | What it does |
|---|---|
| [`Send-TimeOffBalanceEmails.ps1`](Reporting/Send-TimeOffBalanceEmails.ps1) | Mail-merges vacation / long-service balances from a CSV into Outlook emails. |

## Profile

| Script | What it does |
|---|---|
| [`team-profile.ps1`](Profile/team-profile.ps1) | The two-line `$PROFILE` every team machine had: runs `System.Profile` from the internal feed, then loads the Chocolatey profile. |
| [`System.Profile.ps1`](Profile/System.Profile.ps1) | Welcome banner plus a weekly check that installs/uninstalls modules and scripts to match the internal PSGallery feed. |

## Requirements

- Windows PowerShell 5.1
- RSAT `ActiveDirectory` and `GroupPolicy` modules for anything touching AD/GPO
- `MSOnline`, Exchange Online remoting and `SkypeOnlineConnector` for the Office 365 pieces (these pre-date the Graph / EXO V2 modules)
- `VirtualMachineManager` (SCVMM) and NetApp `DataONTAP` for the storage / Hyper-V reports
- The modules expect each other: `Automation`, `Office365` and most scheduled tasks call `Get-ConfigItem` from `Config`

## Notes

- Scripts in `ScheduledTasks/` were published to an internal PSGallery feed and installed with `Install-Script`; the profile kept them current.
- Many scripts carry their original comment-based help. Where a script only had a placeholder, I added a short `.SYNOPSIS`/`.DESCRIPTION`.
- This is a portfolio snapshot, not a maintained toolset — most of the Office 365 cmdlets used here have since been replaced by Microsoft.

## License

My code in this repository is released under [CC0 1.0](LICENSE). Scripts in `third-party/` and the bundled
community functions noted in [third-party/README.md](third-party/README.md) remain under their original authors' terms.
