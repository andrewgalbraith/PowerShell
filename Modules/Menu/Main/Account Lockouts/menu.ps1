<#
.SYNOPSIS
 Check an account
#>

$userInput="50"
$OutputPath = "C:\Account_Lockout"

Write-Host "What would you like to do?"
Write-Host
Write-Host "1. Check Account lockout now"
Write-Host "2. Run Script in loop to take logs when account locks out"
Write-Host

Write-Host "Logs can be found in: " -NoNewline
Write-Host  $OutputPath -BackgroundColor Yellow -ForegroundColor Red -NoNewline

Write-Host
Write-Host

[int]$userInput = User-Input "Select Option (0 = Quit and Exit)"

[String]$userID = User-Input "Account lockout: Enter user ID (e.g ab123456)"
[int]$unlock = User-Input "Unlock Account: 0=No, 1=Yes"

Write-Host
Write-Host "What is Advance logs. If you enable advance logs then it will " -NoNewline
Write-Host "scan account locks out with EventCombMT and also it will copy netlogon logs from each server" -NoNewline
Write-Host

[int]$advanceLog = User-Input "Take Advance Logs: 0=No, 1=Yes"

$exp = "Check-AccountLockout -UserID `$userID -OutputPath `$OutputPath "
if($unlock) { $exp += "-Unlock" }
if($advancelog) { $exp += "-Advanced" }

switch($userInput) {
    0 { exit 1 }
    1 { Invoke-Expression $exp }
    2 { Invoke-Expression ($exp + " -Iterations 2 -WaitForLockout") }
}
