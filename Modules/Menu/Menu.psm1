function Menu
{
    $HostUi = (Get-Host).UI.RawUI
    $HostUi.WindowSize.Width = 80
    $HostUi.WindowSize.Height = 20
    $HostUi.WindowTitle = "User Management Console"

    Write-Host $Menus.WelcomeText -BackgroundColor "DarkGreen"
    Out-Menu -MenuPath "Main"
}

function Out-Menu
{
    param([string] $MenuPath, [switch]$NoClear)

    if(!$NoClear) { Clear-Host }

    # Determine the absolute path to the menu (if not already)
    $FullMenuPath = $MenuPath
    if($FullMenuPath -notlike "$psScriptRoot*" )
    {
        $FullMenuPath = Join-Path $psScriptRoot $MenuPath
    }

    # Locate child items of the specified path which are either directories
    # (sub-menus) or actions (script files), then sort them by item type then
    # by name
    $items = $FullMenuPath | Get-ChildItem | 
        Where-Object {$_.Mode -like "d*" -or $_.name -like "*.ps1"} |
        Sort-Object Mode,Name

    # Display a breadcrumb trail to give an indication of position in the 
    # system
    Out-Breadcrumb $FullMenuPath

    # Display the menu items
    Out-MenuItems $items
    
    Write-Host "" # Blank line

    # Collect menu choice from user, ensuring correct entry
    $choice = -1
    while(($choice -gt $items.count) -or ($choice -lt 0)) 
    {
        [int]$choice = Read-Host "Please enter your choice (blank to go up)"
    }


    # If the choice was 0, go up a level
    if($choice -eq 0)
    {
        if($FullMenuPath -ne (Join-Path $psScriptRoot "Main"))
        {
            Out-Menu (Split-Path $FullMenuPath)
        }
        else 
        {
            Out-Menu $FullMenuPath
        }
    } 
   else
    {
        $item = $items[$choice-1]
        
        # If the selection is a submenu, show it. Otherwise run the selected menu
        # action.
        if($item.Mode -like "d*")
        {
            Out-Menu (Join-Path $FullMenuPath $item.Name)
        } 
        else
        {
            Invoke-ChosenCommand $item
        }        
    }
}

function Out-MenuItems 
{
    param($items)
    
    $i = 1;
    foreach($item in $items)
    {
        if($item.Mode -like "*d*")
        {
            Write-Host ("$i. -> ") -NoNewLine
            Write-Host $item -ForegroundColor Yellow
        }
        else
        {
            $name = Get-Help $item.FullName | 
                Select-Object -expandproperty Synopsis
            Write-Host ("$i. $name")
        }
        $i++
    }
}

function Invoke-ChosenCommand
{
    param($script)
    
    # Clear the stage for the command
    Clear-Host
    
    # Run the script behind the command
    . $script.FullName
    
    # Pause to see results
    Pause

    # Return to the previous menu
    Out-Menu (Split-Path $script.FullName)
}

function Out-Breadcrumb
{
    param($absolutepath)

    $relative_path = $absolutepath.substring($psscriptroot.length)
    Write-Host $relative_path.replace("\"," / ") " `n" -BackgroundColor DarkGreen
}

Export-ModuleMember -Function Menu
