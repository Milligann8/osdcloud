# oobetasks.osdcloud.ch

# Paths
$scriptFolderPath = "$env:SystemDrive\OSDCloud\Scripts"
$ScriptPathOOBE = Join-Path -Path $scriptFolderPath -ChildPath "OOBE.ps1"
$ScriptPathSendKeys = Join-Path -Path $scriptFolderPath -ChildPath "SendKeys.ps1"

# Create Script Folder
If (!(Test-Path -Path $scriptFolderPath)) {
    New-Item -Path $scriptFolderPath -ItemType Directory -Force | Out-Null
}

# -------------------------
# OOBE.ps1
# -------------------------
$OOBEScript = @"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OOBEScripts.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Installing OSD Module"
Install-Module OSD -Force -Verbose

Write-Host -ForegroundColor DarkGray "Setting Keyboard Layout"
Invoke-WebPSScript https://raw.githubusercontent.com/Milligann8/osdcloud/refs/heads/main/ScriptPad/keyboard-language.ps1

Write-Host -ForegroundColor DarkGray "Injecting Embedded Product Key"
Invoke-WebPSScript https://raw.githubusercontent.com/Milligann8/osdcloud/refs/heads/main/ScriptPad/embeddedkey.ps1

Write-Host -ForegroundColor DarkGray "Running Start-OOBEDeploy"
Start-OOBEDeploy

Write-Host -ForegroundColor DarkGray "Running Cleanup Script"
Invoke-WebPSScript https://raw.githubusercontent.com/Milligann8/osdcloud/refs/heads/main/ScriptPad/cleanup.ps1

# --- Create a local user ---
Write-Host -ForegroundColor DarkGray "Creating local user"
`$Username = "ariadmin"
`$Password = ConvertTo-SecureString "" -AsPlainText -Force
New-LocalUser -Name `$Username -Password `$Password -FullName "OSD User" -Description "Local user created by OSDCloud"
Add-LocalGroupMember -Group "Administrators" -Member `$Username

# --- Setup AutoLogin ---
Write-Host -ForegroundColor DarkGray "Setting auto-login"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /t REG_SZ /d 1 /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /t REG_SZ /d `$Username /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /t REG_SZ /d "" /f

# --- Finalize OOBE ---
Write-Host -ForegroundColor DarkGray "Finishing OOBE"
Start-Process -FilePath "C:\Windows\System32\oobe\msoobe.exe" -ArgumentList "/oobe /unattend" -Wait

# --- Cleanup Scheduled Tasks ---
Unregister-ScheduledTask -TaskName "Scheduled Task for SendKeys" -Confirm:`$false -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName "Scheduled Task for OSDCloud post installation" -Confirm:`$false -ErrorAction SilentlyContinue

Write-Host -ForegroundColor DarkGray "Restarting computer"
Restart-Computer -Force

Stop-Transcript
"@

Out-File -FilePath $ScriptPathOOBE -InputObject $OOBEScript -Encoding ascii

# -------------------------
# SendKeys.ps1
# -------------------------
$SendKeysScript = @"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-SendKeys.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Sending ALT+TAB and SHIFT+F10 to exit OOBE debug window"
`$WscriptShell = New-Object -com Wscript.Shell
`$WscriptShell.SendKeys("%({TAB})")
Start-Sleep -Seconds 1
`$WscriptShell.SendKeys("+({F10})")

Stop-Transcript
"@

Out-File -FilePath $ScriptPathSendKeys -InputObject $SendKeysScript -Encoding ascii

# -------------------------
# Download ServiceUI.exe
# -------------------------
Write-Host -ForegroundColor Gray "Downloading ServiceUI.exe"
Invoke-WebRequest https://github.com/Milligann8/osdcloud/raw/refs/heads/main/ScriptPad/ServiceUI.exe -OutFile "C:\OSDCloud\ServiceUI.exe"

# -------------------------
# Scheduled Task: SendKeys
# -------------------------
$TaskName = "Scheduled Task for SendKeys"
$ShedService = New-Object -comobject 'Schedule.Service'
$ShedService.Connect()
$Task = $ShedService.NewTask(0)
$Task.RegistrationInfo.Description = $TaskName
$Task.Settings.Enabled = $true
$Task.Settings.AllowDemandStart = $true
$trigger = $Task.Triggers.Create(9) # Logon Trigger
$trigger.Delay = 'PT15S'
$trigger.Enabled = $true
$action = $Task.Actions.Create(0)
$action.Path = 'C:\OSDCloud\ServiceUI.exe'
$action.Arguments = '-process:RuntimeBroker.exe powershell.exe -ExecutionPolicy Bypass -File "' + $ScriptPathSendKeys + '"'
$taskFolder = $ShedService.GetFolder("\")
$taskFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $null, 5)

# -------------------------
# Scheduled Task: OOBE.ps1
# -------------------------
$TaskName = "Scheduled Task for OSDCloud post installation"
$Task = $ShedService.NewTask(0)
$Task.RegistrationInfo.Description = $TaskName
$Task.Settings.Enabled = $true
$Task.Settings.AllowDemandStart = $true
$trigger = $Task.Triggers.Create(9)
$trigger.Delay = 'PT20S'
$trigger.Enabled = $true
$action = $Task.Actions.Create(0)
$action.Path = 'C:\OSDCloud\ServiceUI.exe'
$action.Arguments = '-process:RuntimeBroker.exe powershell.exe -ExecutionPolicy Bypass -File "' + $ScriptPathOOBE + '"'
$taskFolder.RegisterTaskDefinition($TaskName, $Task, 6, "SYSTEM", $null, 5)
