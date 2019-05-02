#Config file locations
$global:GlobalConfigFile = "\\contoso.com\global\IT\Scripts\Powershell\Configuration\Global\config.xml"
$global:UserConfigFile = Join-Path (Split-Path $profile) "PowerShell.config.xml"
$global:ScriptConfigPath = "\\contoso.com\global\IT\Scripts\Powershell\Configuration\Script"
$global:ScriptConfigFile = $null

# Define the config variable
$config = @{}

# Check for and import the global configuration
if(-not (Test-Path $GlobalConfigFile)) {
    $config['global'] = @{}
    $config['global'] | Export-Clixml $GlobalConfigFile
} else {
    $config['global'] = Import-Clixml $GlobalConfigFile
}


# Check for and import User configuration
if(-not (Test-Path $UserConfigFile)) {
    $config['user'] = @{}
    $config['user'] | Export-Clixml $UserConfigFile
} else {
    $config['user'] = Import-Clixml $UserConfigFile
}

function Import-ScriptConfig
{
    if(-not $MyInvocation.PSCommandPath)
    {
        throw 'No script currently executing.'
    }

    # Check for and import script configuration
    $ScriptFileName = Split-Path $MyInvocation.PSCommandPath -Leaf
    $global:ScriptConfigFile = Join-Path $ScriptConfigPath ($ScriptFileName + ".config.xml")

    if(-not (Test-Path $ScriptConfigFile))
    {
        $config['script'] = @{}
        $config['script'] | Export-Clixml $ScriptConfigFile 
    } else {
        # Load the script configuration file
        $config['script'] = Import-Clixml $ScriptConfigFile
    }
}

# Adds a config item to the specified scope, defaults to user
function Set-ConfigItem
{
    param($Key, $Value, $Scope)
    
    if(-not $Scope -or -not $Key)
    {
        throw 'Scope and key parameters must be provided'
    }
    # If the scope exists, add or set the item in the scope.
    if($Config[$Scope])
    {
        $Config[$Scope][$Key] = $Value
    }
    else 
    {
        throw "Scope not available or not initialised. Valid scopes are 'user', 'script' or 'global'"
    }
    
    # Also, update the config files
    Write-Config
}

# Retrieves the config items in order of priority: script -> user -> global
function Get-ConfigItem
{
    param($Key)

    if($config['script'] -and $config['script'][$key])
    {
        $config['script'][$key]
    }
    else
    {
        if($config['user'][$key])
        {
            $config['user'][$key]
        }
        else
        {
            $config['global'][$key]
        }
    }
}

function Remove-ConfigItem
{
    param($Key, $Scope)
    if(-not $Scope)
    {
        throw 'Scope must be defined to remove an item.'
    }
    else
    {
        $config[$scope].Remove($Key)
    }

    # Also, update the config files    
    Write-Config $MyInvocation.PSCommandPath
}

function Get-Config
{
    param($Scope)
    
    if($Scope)
    {
        $config[$Scope].GetEnumerator() | 
            Sort-Object Name
    }
    else
    {
        foreach($scope in $config.GetEnumerator())
        {
                Write-Verbose $scope.Name "scope" -ForegroundColor White -BackgroundColor Green
                $scope.Value.GetEnumerator() | Sort-Object Name
        }
    }
}

function Write-Config
{
    $config['global'] | Export-Clixml -Path $GlobalConfigFile
    $config['user'] | Export-Clixml -Path $UserConfigFile
    
    if($config['script'])
    {
        $config['script'] | Export-Clixml -Path $ScriptConfigFile
    }
}

Export-ModuleMember -Function Set-ConfigItem,Get-ConfigItem,Remove-ConfigItem,Get-Config,Read-Config,Import-ScriptConfig
