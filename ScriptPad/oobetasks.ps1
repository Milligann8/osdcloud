# oobetasks.osdcloud.ch

$scriptFolderPath = "$env:SystemDrive\OSDCloud\Scripts"
$ScriptPathOOBE = Join-Path -Path $scriptFolderPath -ChildPath "OOBE.ps1"
$ScriptPathSendKeys = Join-Path -Path $scriptFolderPath -ChildPath "SendKeys.ps1"

If (!(Test-Path -Path $scriptFolderPath)) {
    New-Item -Path $scriptFolderPath -ItemType Directory -Force | Out-Null
}

# Create OOBE.ps1 script
$OOBEScript = @"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OOBEScripts.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Installing OSD PS Module"
Start-Process PowerShell -ArgumentList "-NoL -C Install-Module OSD -Force -Verbose" -Wait

Write-Host -ForegroundColor DarkGray "Executing Keyboard Language Script"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Milligann8/osdcloud/refs/heads/main/ScriptPad/keyboard-language.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Executing Product Key Script"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Milligann8/osdcloud/refs/heads/main/ScriptPad/embeddedkey.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Executing OOBEDeploy Script from OSDCloud Module"
Start-Process PowerShell -ArgumentList "-NoL -C Start-OOBEDeploy" -Wait

Write-Host -ForegroundColor DarkGray "Executing Cleanup Script"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://raw.githubusercontent.com/Milligann8/osdcloud/refs/heads/main/ScriptPad/cleanup.ps1" -Wait

# Disable OOBE Prompts
Write-Host -ForegroundColor DarkGray "Marking OOBE as completed"
Set-ItemProperty -Path "HKLM:\SYSTEM\Setup" -Name "OOBEInProgress" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\Setup" -Name "SetupPhase" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SYSTEM\Setup" -Name "SetupType" -Value 0 -Force

# Optional: Auto-login setup (lab use only)
Write-Host -ForegroundColor DarkGray "Configuring Auto-Login (use only in lab/test)"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "AutoAdminLogon" -Value "1" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultUsername" -Value "Test" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name "DefaultPassword" -Value "" -Force

# Cleanup Scheduled Tasks
Write-Host -ForegroundColor DarkGray "Unregistering Scheduled Tasks"
Unregister-ScheduledTask -TaskName "Scheduled Task for SendKeys" -Confirm:`$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "Scheduled Task for OSDCloud post installation" -Confirm:`$false -ErrorAction SilentlyContinue

# Optional: Final Cleanup
Write-Host -ForegroundColor DarkGray "Removing OSDCloud setup files"
Remove-Item -Path "C:\OSDCloud" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "`$env:SystemDrive\OSDCloud\Scripts" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host -ForegroundColor DarkGray "Restarting Computer"
Restart-Computer -Force

Stop-Transcript -Verbose | Out-File
"@
Out-File -FilePath $ScriptPathOOBE -InputObject $OOBEScript -Encoding ascii

# Create SendKeys.ps1 script
$SendKeysScript = @"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-SendKeys.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Stop Debug-Mode (SHIFT + F10) with WscriptShell.SendKeys"
`$WscriptShell = New-Object -com Wscript.Shell

# ALT + TAB
Write-Host -ForegroundColor DarkGray "SendKeys: ALT + TAB"
`$WscriptShell.SendKeys("%({TAB})")
Start-Sleep -Seconds 1

# Shift + F10
Write-Host -ForegroundColor DarkGray "SendKeys: SHIFT + F10"
`$WscriptShell.SendKeys("+({F10})")

Stop-Transcript -Verbose | Out-File
"@
Out-File -FilePath $ScriptPathSendKeys -InputObject $SendKeysScript -Encoding ascii

# Download ServiceUI.exe
Write-Host -ForegroundColor Gray "Download ServiceUI.exe from GitHub Repo"
Invoke-WebRequest https://github.com/Milligann8/osdcloud/raw/refs/heads/main/ScriptPad/ServiceUI.exe -OutFile "C:\OSDCloud\ServiceUI.exe"

# Create Scheduled Task for SendKeys with 15 seconds delay
$TaskName = "Scheduled Task for SendKeys"
$ShedService = New-Object -comobject 'Schedule.Service'
$ShedService.Connect()

$Task = $ShedService.NewTask(0)
$Task.RegistrationInfo.Description = $taskName
$Task.Settings.Enabled = $true
$Task.Settings.AllowDemandStart = $true
$trigger = $Task.Triggers.Create(9)
$trigger.Delay = 'PT15S'
$trigger.Enabled = $true
$action = $Task.Actions.Create(0)
$action.Path = 'C:\OSDCloud\ServiceUI.exe'
$action.Arguments = '-process:RuntimeBroker.exe C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe ' + $ScriptPathSendKeys + ' -NoExit'
$ShedService.GetFolder("\").RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $NULL, 5)

# Create Scheduled Task for OOBE script with 20 seconds delay
$TaskName = "Scheduled Task for OSDCloud post installation"
$Task = $ShedService.NewTask(0)
$Task.RegistrationInfo.Description = $taskName
$Task.Settings.Enabled = $true
$Task.Settings.AllowDemandStart = $true
$trigger = $Task.Triggers.Create(9)
$trigger.Delay = 'PT20S'
$trigger.Enabled = $true
$action = $Task.Actions.Create(0)
$action.Path = 'C:\OSDCloud\ServiceUI.exe'
$action.Arguments = '-process:RuntimeBroker.exe C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe ' + $ScriptPathOOBE + ' -NoExit'
$ShedService.GetFolder("\").RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $NULL, 5)
