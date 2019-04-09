<#
.SYNOPSIS
  Locates paths with lenghts incompatible with with Windows Explorer
.DESCRIPTION
  Receives a list of path or share names and recursively scans through the folder 
  structure. Any path related errors are captured and output at the end of the
  script.
.EXAMPLE
  # Defaults to 10 characters
  LocateIncompatiblePaths -Path \\FILER03\CMM -OutputDirectory C:\
.PARAMETER Path
  A path or list of paths to scan
.PARAMETER OutputDirectory
  A folder to output the CSV file
#>

function LocateIncompatiblePaths {

  param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String[]]
    $Path,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $OutputDirectory
  )

  $csv = @()

  Foreach-Object -InputObject $Path -Process {

    if(Test-Path $_)
    {
      # Recusrively scan the current directory, keeping errors in the $errors variable
      # and not outputting the results
      Get-ChildItem $_ -Recurse -ErrorVariable errors -ErrorAction SilentlyContinue | Out-Null
      
      # Pull the attributes we want from the errors
      $errors_processed = $errors | % -MemberName CategoryInfo | Select TargetName,Category,Reason
      
      # Add the results to the hash for output to CSV
      $csv += $errors_processed
      
      # If the verbose flag is set, output the results
      if($Verbose)
      {
        $errors_processed | ft
      }
    }
  }

  # If the output directory exists, try and write the results to a CSV
  if(Test-Path $OutputDirectory)
  {
    # Generate filename with current timestamp
    $filename = $OutputDirectory + "IncompatiblePaths-" + (Get-Date).ToFileTimeUtc() + ".csv"
    
    # Send the results to the file or output the error
    try
    {
        $csv | Export-CSV -Path $filename -NoTypeInformation
    }
    catch
    {
        Write-Host "Error: Output file could not be written" -BackgroundColor Red
        Write-Host $_.Message
    }
  }
  else
  {
    # Otherwise display a message
    Write-Host "Output directory does not exist or is not accessible" -BackgroundColor Red
  }
}
