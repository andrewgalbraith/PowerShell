$functions_dir = Join-Path $PSScriptRoot "functions"
$workflows_dir = Join-Path $PSScriptRoot "workflows"

# Import function files
@($functions_dir, $workflows_dir) | 
    Get-ChildItem -Filter *.ps1 |
    Foreach-Object { . $_.FullName }

function Start-AutomatedTask
{
    param(        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $Name,
        [Array]
        $TranscriptRecipients,
        [Switch]
        $NoTranscript,
        [Hashtable]$parameters
    )

    # Transcribe console output to file for error resolution
    if(!$NoTranscript)
    {
        $TranscriptDir = Get-ConfigItem -Key "Automation.TranscriptDir"
        $TranscriptFile = Join-Path $TranscriptDir ($Name + "." + (Get-Date).ToFileTime() + ".log")
        Start-Transcript -Path $TranscriptFile
    }

    $ScriptPath = (Get-ConfigItem Automation.ScriptFolder) + $Name + ".ps1"
    
    $Result = ""
    if(Test-Path $ScriptPath -Verbose)
    {
        $Result = (. $ScriptPath @parameters)
    }
    $Result

    # Stop the transcript
    if(!$NoTranscript)
    {
        Stop-Transcript
    }

    # Work out who to send the transcripts to
    $recipients = @()
    if($TranscriptRecipients)
    {
        $recipients = $TranscriptRecipients
    }

    # Add my email address if no others specified
    if($recipients.Count -eq 0) 
    {    
        $recipients += (Get-ConfigItem Automation.DefaultTranscriptRecipient)
    }

    if(!$NoTranscript)
    {
        Send-MailMessage -To $recipients -From "OPS Automated Tasks <ops.automatedtasks@contoso.com>" -Subject "Transcript for task $Name" -Attachments $TranscriptFile -SmtpServer smtp.contoso.com -Body "See attached file for transcript. This file and other transcripts can be found at $TranscriptDir"
    }  
}

Export-ModuleMember -Function *
