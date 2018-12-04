<#
    .SYNOPSIS 
			Restore a file of folder from a NetApp snapshot (Not used)
#>

# Explanation about path collection.
Write-Host @"
This script will enable the snapshot visibility of a volume so that you can
browse the snapshots and restore files from them.
    
    1) Provide a path to the file or folder to be restored. DFS is supported.
    2) Select a snapshot from the list
    3) Browse the directory structure to locate the file and then use standard
       filesystem management commands to restore the file or folder (copy / 
       xcopy / robocopy)

NOTE: When restoring from a snapshot using a DFS path, the script needs to resolve
the underlying filer name to generate an absolute path. If the file or folder to 
restore does not exist (it has been deleted) the absolute path cannot be determined.
"@

# 1. Collect path information
$source_path = (read-host "Provide the original path to the file or folder`n")
