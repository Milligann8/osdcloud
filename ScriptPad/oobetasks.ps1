# Wait for network connection
$ProgressPreference_bk = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'
do {
    if (!(Test-NetConnection '8.8.8.8' -InformationLevel Quiet)) {
        Clear-Host
        Write-Host "Waiting for network connection..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
} while (!(Test-NetConnection '8.8.8.8' -InformationLevel Quiet))
$ProgressPreference = $ProgressPreference_bk



# Configure location privacy settings
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy /v LetAppsAccessLocation /t REG_DWORD /d 1 /f 

# Set time zone
Set-TimeZone -ID "Mountain Standard Time"

# Sync system time
w32tm /resync /force 

# Ensure the Windows Update module is installed
if (-not (Get-Module -Name PSWindowsUpdate -ListAvailable)) {
    Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
    Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
    Import-Module PSWindowsUpdate
}

# Enable Microsoft Update (not just Windows Update)
Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -AddServiceFlag 7 -Confirm:$False

# Set Windows Update categories
$UpdateCategories = @(
    "Security Updates", "Critical Updates", "Drivers", "Feature Packs",
    "Definition Updates", "Service Packs", "Tools", "Update Rollups", "Updates"
)

# Fetch updates that match the specified categories
$Updates = Get-WindowsUpdate -MicrosoftUpdate -Category $UpdateCategories -AcceptAll

# Install updates if available, without automatic reboot
if ($Updates) {
    Write-Host "Installing updates..."
    Install-WindowsUpdate -AcceptAll -IgnoreReboot
} else {
    Write-Host "No updates available."
}

$status = Get-WURebootStatus -Silent

if ($status) {
    $setup_runonce = @{
        Path  = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        Name  = "execute_provisioning"
        Value = "cmd /c powershell.exe -ExecutionPolicy Bypass -File {0}\provisioning.ps1" -f "$($env:ProgramData)\provisioning"
    }
    New-ItemProperty @setup_runonce | Out-Null
    Restart-Computer
}
else {
    # best place to add more actions
}

# Upgrade all available Winget packages
winget upgrade --all --accept-package-agreements --accept-source-agreements

# Disable Bing Search and Cortana
$searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
New-ItemProperty -Path $searchPath -Name "BingSearchEnabled" -Value 0 -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $searchPath -Name "CortanaConsent" -Value 0 -PropertyType DWORD -Force | Out-Null

New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force
New-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "EnableDynamicContentInWSB" -PropertyType DWORD -Value 0
Write-Host "Search Highlights and news & interests removed." -ForegroundColor Green

# Remove unwanted preinstalled apps
$appsToRemove = @(
    "Microsoft.WindowsFeedbackHub", "Microsoft.MicrosoftFamily", "Microsoft.WindowsMaps", "Microsoft.Todos", "Microsoft.OneNote",
    "Microsoft.MicrosoftStickyNotes", "Microsoft.ZuneVideo", "Microsoft.ZuneMusic", "DolbyLaboratories.DolbyAccess", "Microsoft.WindowsCopilot",
    "king.com.CandyCrushSaga", "Microsoft.PowerAutomateDesktop", "Microsoft.OutlookForWindows", "Microsoft.YourPhone",
    "MicrosoftCorporationII.QuickAssist", "Microsoft.MicrosoftSolitaireCollection", "Microsoft.MicrosoftMahjong", "Microsoft.MicrosoftMinesweeper",
    "Microsoft.MicrosoftJigsaw", "Microsoft.BingSports", "Microsoft.BingNews", "Microsoft.BingWeather", "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay", "Microsoft.Xbox.TCUI", "Microsoft.XboxApp", "Microsoft.XboxSpeechToTextOverlay", "Microsoft.XboxIdentityProvider",
    "Microsoft.GamingApp", "MSTeams", "Microsoft.MicrosoftOfficeHub"
)
foreach ($app in $appsToRemove) {
    Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*$app*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}
Write-Host "All specified apps have been removed." -ForegroundColor Green


# Remove Microsoft Office
$odtPath = "$env:ProgramData\provisioning"
$setupFile = "$odtPath\setup.exe"
$xmlFile = "$odtPath\remove-office.xml"
if (Test-Path -Path $setupFile) {
    Start-Process -FilePath $setupFile -ArgumentList "/configure $xmlFile" -NoNewWindow -Wait
    Write-Host "Office removal process started." -ForegroundColor Green
} else {
    Write-Host "Error: setup.exe not found in $odtPath" -ForegroundColor Red
}

# Uninstall OneDrive
$onedrive = "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
if (Test-Path $onedrive) {
    Start-Process -FilePath $onedrive -ArgumentList "/uninstall" -NoNewWindow -Wait
    Write-Host "OneDrive uninstalled." -ForegroundColor Green
}



# Set default app associations for newly added users only
$associationsPath = "$env:ProgramData\provisioning\associations.xml"
@"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
    <Association Identifier=".htm" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
    <Association Identifier=".html" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
    <Association Identifier="http" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
    <Association Identifier="https" ProgId="ChromeHTML" ApplicationName="Google Chrome" />
</DefaultAssociations>
"@ | Out-File $associationsPath -Encoding utf8

dism /online /Import-DefaultAppAssociations:"$associationsPath"

Write-Host "Chrome set as default." -ForegroundColor Green

# Remove provisioning folder
Remove-Item -Path "$env:ProgramData\provisioning" -Recurse -Force
Write-Host "Provisioning folder deleted." -ForegroundColor Green

# Remove 'ariadmin' user if it exists
$user = "ariadmin"
if (Get-WmiObject Win32_UserAccount -Filter "Name='$user'") {
    net user $user /delete
    Write-Host "User '$user' removed successfully." -ForegroundColor Green
}

#Checks currently connected SSID from Provisioning package and removes it
$SSID = (netsh wlan show interfaces | Select-String " SSID" | ForEach-Object { ($_ -split ":")[1] -replace "^\s+|\s+$", "" })

if ($SSID -match "^(.*?)(\s{2,}|$)") {
    $SSID = $matches[1]
    Write-Host "Connected to SSID: '$SSID'"
    Write-Host "Forgetting SSID: '$SSID'"
    netsh wlan delete profile name="$SSID"
    Write-Host "SSID '$SSID' forgotten."
} else {
    Write-Host "No Wi-Fi connection detected."
}


# Play completion sound and restart system
[console]::beep(400, 2000)
Write-Host "Provisioning completed! Restarting in 20 seconds..." -ForegroundColor Cyan
Start-Sleep -Seconds 20
Restart-Computer -Force

