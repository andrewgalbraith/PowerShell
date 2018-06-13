function Get-WindowsVersion {
<#
.SYNOPSIS
    Lists the Windows version and build of local, remote or AD-scoped computers.
.NOTES
    The copy this was recovered from had lost its opening lines; the function wrapper and
    .SYNOPSIS were restored so the file parses. Everything below is the original.
.LINK    
    https://www.dertechblog.de
.EXAMPLE    
    Get-WindowsVersion
    List Windows Version on local computer with built-in Format-Table and Sort-Object.
.EXAMPLE    
    Get-WindowsVersion -ComputerName WORKSTATION01
    List Windows Version on remote computer with built-in Format-Table and Sort-Object.
.EXAMPLE    
    Get-WindowsVersion -ComputerName pc1,pc2
    List Windows Version on multiple remote computer with built-in Format-Table and Sort-Object.
.EXAMPLE    
    Get-WindowsVersion -SearchBase "OU=Computers,DC=comodo,DC=com" with built-in Format-Table and Sort-Object.
    List Windows Version on Active Directory SearchBase computer. 
.EXAMPLE    
    Get-WindowsVersion -ComputerName pc1,pc2 -Force
    List Windows Version on multiple remote computer and disable the built-in Format-Table and Sort-Object.
.EXAMPLE    
    Get-WindowsVersion -History with built-in Format-Table and Sort-Object.
    List History Windows Version on local computer.   
.EXAMPLE    
    Get-WindowsVersion -ComputerName pc1,pc2 -History
    List History Windows Version on multiple remote computer with built-in Format-Table and Sort-Object.
.EXAMPLE    
    Get-WindowsVersion -ComputerName pc1,pc2 -History -Force
    List History Windows Version on multiple remote computer and disable built-in Format-Table and Sort-Object.                    
#>  
    [cmdletbinding()]
    param (
        [parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName = "localhost",
        [string]$SearchBase,
        [switch]$History,
        [switch]$Force
    )
    if ($($PsVersionTable.PSVersion.Major) -gt "2" ) {
        # SearchBase
        if ($SearchBase) {
            if (Get-Command Get-AD* -ErrorAction SilentlyContinue) {
                if (Get-ADOrganizationalUnit -Filter "distinguishedName -eq '$SearchBase'" -ErrorAction SilentlyContinue) {
                    $Table = Get-ADComputer -SearchBase $SearchBase -Filter *
                    $ComputerName = $Table.Name
                }
                else {Write-Warning "No SearchBase found"}
            }
            else {Write-Warning "No AD Cmdlet found"}
        }
        # Loop 1
        $Tmp = New-TemporaryFile
        foreach ($Computer in $ComputerName) {
            if (Test-Connection -ComputerName $Computer -Count 1 -ErrorAction SilentlyContinue) { 
                if (Get-Item -Path "\\$Computer\c$" -ErrorAction SilentlyContinue) {                    
                    # Variables
                    $WMI = [WmiClass]"\\$Computer\root\default:stdRegProv"
                    $HKLM = 2147483650
                    $Reg1 = "SOFTWARE\Microsoft\Windows NT\CurrentVersion"
                    $Reg2 = "SYSTEM\Setup"
                    if ($History) {$KeyArr = ($WMI.EnumKey($HKLM, $Reg2)).snames -like "Source*"} else {$KeyArr = $Reg1}
                    # Loop 2
                    foreach ($Key in $KeyArr) {                        
                        if ($History) {$Reg = "$Reg2\$Key"} else {$Reg = $Key}
                        $Major = $WMI.GetDWordValue($HKLM, $Reg, "CurrentMajorVersionNumber").UValue
                        $Minor = $WMI.GetDWordValue($HKLM, $Reg, "CurrentMinorVersionNumber").UValue
                        $Build = $WMI.GetStringValue($HKLM, $Reg, "CurrentBuildNumber").sValue
                        $UBR = $WMI.GetDWordValue($HKLM, $Reg, "UBR").UValue
                        $ReleaseId = $WMI.GetStringValue($HKLM, $Reg, "ReleaseId").sValue
                        $ProductName = $WMI.GetStringValue($HKLM, $Reg, "ProductName").sValue
                        $ProductId = $WMI.GetStringValue($HKLM, $Reg, "ProductId").sValue
                        $InstallTime = ([datetime]::FromFileTime($WMI.GetQWordValue($HKLM, $Reg, "InstallTime").UValue))
                        # Variables Windows 6.x
                        if ($Major.Length -le 0) {$Major = $WMI.GetStringValue($HKLM, $Reg, "CurrentVersion").sValue}                            
                        if ($ReleaseId.Length -le 0) {$ReleaseId = $WMI.GetStringValue($HKLM, $Reg, "CSDVersion").sValue}
                        # Add Points
                        if (-not($Major.Length -le 0)) {$Major = "$Major."}
                        if (-not($Minor.Length -le 0)) {$Minor = "$Minor."}
                        if (-not($UBR.Length -le 0)) {$UBR = ".$UBR"}
                        # Output
                        $Output = New-Object -TypeName PSobject                     
                        $Output | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.toUpper()
                        $Output | Add-Member -MemberType NoteProperty -Name ProductName -Value $ProductName
                        $Output | Add-Member -MemberType NoteProperty -Name WindowsVersion -Value $ReleaseId
                        $Output | Add-Member -MemberType NoteProperty -Name WindowsBuild -Value "$Major$Minor$Build$UBR"
                        $Output | Add-Member -MemberType NoteProperty -Name ProductId -Value $ProductId
                        $Output | Add-Member -MemberType NoteProperty -Name InstallTime -Value $InstallTime
                        $Output | Export-Csv -Path $Tmp -Append
                    }
                }
                else {Write-Warning "$Computer no access"}
            }
            else {Write-Warning "$Computer not reachable"}      
        }
        # Output
        if ($Force) {Import-Csv -Path $Tmp} else {Import-Csv -Path $Tmp | Sort-Object -Property ComputerName, WindowsVersion | Format-Table -AutoSize}
    }
    else {Write-Warning "PSVersion to low"}
}
