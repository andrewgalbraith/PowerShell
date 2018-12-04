<#
.SYNOPSIS
    Schedule a VM migration
.DESCRIPTION
    Schedules a VM migration
#>

try 
{
    
    $options = @{}

    if($host.Version.Major -lt 4)
    {
        throw "Please use Windows 8/2012 or higher for this script."
    }
    
    $cred = Get-ExchangeOnlineCredentials
    if(-not $cred)
    {
        throw "Please store your credentials (menu option 1) before continuing"
    }

    do 
    {
        $options.VMName = Read-Host "Enter VM name"
    } 
    while (-not $options.VMName)

    do
    {
        $options.Destination = Read-Host "Enter destination host or cluster"
        $found = Get-SCVMHostCluster | Where-Object ClusterName -eq $options.Destination
        $options.DestinationType = "Cluster"
        if(-not $found) {
            $found = Get-SCVMHost $options.Destination -ErrorAction SilentlyContinue
            $options.DestinationType = "Standalone"
        }
    }
    while(-not $found)

    if($options.DestinationType -eq "Standalone") {
        $vmhost = Get-VMHost $options.Destination
        do {
            Write-Host "NOTE: Placement path given must be defined on the host"
            $options.Path = Read-Host "Please enter placement path (e.g. E:\Hyper-V) "
        } while ($options.Path -notin $vmhost.VMPaths)
    }
    
    Write-Output "Date should be in the format 23/09/2016 13:00"
    do 
    {
        $options.Date = Get-Date(Read-Host "Enter migration date and time")
    }
    while (-not $options.Date)

    if($options.DestinationType -eq "Cluster") {
        $action_args = "-Command `"Start-LegacyVMMigration -VMName '" + $options.VMName +
            "' -DestinationCluster '" + $options.Destination + "'`""
    } else {
        $action_args = "-Command `"Start-LegacyVMMigration -VMName '" + $options.VMName +
            "' -DestinationHost '" + $options.Destination + 
            "' -Path '" + $options.Path + "'`""
    }
    Write-Verbose "Command to execute would be"
    Write-Verbose "`t $action_args"         
    
    $action = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument $action_args `
        -Id $options.VMName

    $trigger = New-ScheduledTaskTrigger -At $options.Date -Once
    
    $description = "Migration schedule for" + $options.VMName
    
    Register-ScheduledTask -CimSession "VMM02" `
        -Action $action `
        -Trigger $trigger `
        -User $cred.Username `
        -Password $cred.GetNetworkCredential().password `
        -Description $description `
        -TaskName $options.VMName `
        -TaskPath "\VM Migrations"
}
catch 
{
    Write-Error $_.Exception
}
