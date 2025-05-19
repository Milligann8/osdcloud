[CmdletBinding()]
param()
#region Initialize

#Start the Transcript
$Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud.log"
$null = Start-Transcript -Path (Join-Path "$env:SystemRoot\Temp" $Transcript) -ErrorAction Ignore

#=================================================
#   oobeCloud Settings
#=================================================
$Global:oobeCloud = @{
    oobeSetDisplay = $true
    oobeSetRegionLanguage = $true
    oobeSetDateTime = $true
    oobeRemoveAppxPackage = $true
    oobeRemoveAppxPackageName = 'ActiproSoftwareLLC","AdobeSystemsIncorporated.AdobePhotoshopExpress","BubbleWitch3Saga","CandyCrush","DevHome","Disney","Dolby","Duolingo-LearnLanguagesforFree","EclipseManager","Facebook","Flipboard","gaming","Minecraft","Office","PandoraMediaInc","Royal Revolt","Speed Test","Spotify","Sway","Twitter","Wunderlist","AD2F1837.HPPrinterControl","AppUp.IntelGraphicsExperience","C27EB4BA.DropboxOEM*","Disney.37853FC22B2CE","DolbyLaboratories.DolbyAccess","DolbyLaboratories.DolbyAudio","E0469640.SmartAppearance","Microsoft.549981C3F5F10","Microsoft.AV1VideoExtension","Microsoft.BingNews","Microsoft.BingSearch","Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.GamingApp","Microsoft.Messaging","Microsoft.Microsoft3DViewer","Microsoft.MicrosoftEdge.Stable","Microsoft.MicrosoftJournal","Microsoft.MicrosoftOfficeHub","Microsoft.MicrosoftSolitaireCollection","Microsoft.MixedReality.Portal","Microsoft.MPEG2VideoExtension","Microsoft.News","Microsoft.Office.Lens","Microsoft.Office.OneNote","Microsoft.Office.Sway","Microsoft.OneConnect","Microsoft.People","Microsoft.PowerAutomateDesktop","Microsoft.PowerAutomateDesktopCopilotPlugin","Microsoft.Print3D","Microsoft.RemoteDesktop","Microsoft.SkypeApp","Microsoft.SysinternalsSuite","Microsoft.Teams","Microsoft.Windows.DevHome","Microsoft.WindowsAlarms","Microsoft.windowscommunicationsapps","Microsoft.WindowsFeedbackHub","Microsoft.WindowsMaps","Microsoft.Xbox.TCUI","Microsoft.XboxApp","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay","Microsoft.XboxGamingOverlay_5.721.10202.0_neutral_~_8wekyb3d8bbwe","Microsoft.XboxIdentityProvider","Microsoft.XboxSpeechToTextOverlay","Microsoft.ZuneMusic","Microsoft.ZuneVideo","MicrosoftCorporationII.MicrosoftFamily","MicrosoftCorporationII.QuickAssist","MicrosoftWindows.CrossDevice","MirametrixInc.GlancebyMirametrix","RealtimeboardInc.RealtimeBoard","SpotifyAB.SpotifyMusic","5A894077.McAfeeSecurity","5A894077.McAfeeSecurity_2.1.27.0_x64__wafk5atnkzcwy'
    oobeAddCapability = $false
    oobeAddCapabilityName = 'GroupPolicy','ServerManager','VolumeActivation'
    oobeUpdateDrivers = $true
    oobeUpdateWindows = $true
    oobeRestartComputer = $true
    oobeStopComputer = $false
}

function Step-KeyboardLanguage {

    Write-Host -ForegroundColor Green "Set keyboard language to de-CH"
    Start-Sleep -Seconds 5
    
    $LanguageList = Get-WinUserLanguageList
    
    $LanguageList.Add("de-CH")
    Set-WinUserLanguageList $LanguageList -Force | Out-Null
    
    Start-Sleep -Seconds 5
    
    $LanguageList = Get-WinUserLanguageList
    $LanguageList.Remove(($LanguageList | Where-Object LanguageTag -like 'en-US'))
    Set-WinUserLanguageList $LanguageList -Force | Out-Null
}
function Step-oobeSetDisplay {
    [CmdletBinding()]
    param ()
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeSetDisplay -eq $true)) {
        Write-Host -ForegroundColor Yellow 'Verify the Display Resolution and Scale is set properly'
        Start-Process 'ms-settings:display' | Out-Null
        $ProcessId = (Get-Process -Name 'SystemSettings').Id
        if ($ProcessId) {
            Wait-Process $ProcessId
        }
    }
}
function Step-oobeSetRegionLanguage {
    [CmdletBinding()]
    param ()
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeSetRegionLanguage -eq $true)) {
        Write-Host -ForegroundColor Yellow 'Verify the Language, Region, and Keyboard are set properly'
        Start-Process 'ms-settings:regionlanguage' | Out-Null
        $ProcessId = (Get-Process -Name 'SystemSettings').Id
        if ($ProcessId) {
            Wait-Process $ProcessId
        }
    }
}
function Step-oobeSetDateTime {
    [CmdletBinding()]
    param ()
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeSetDateTime -eq $true)) {
        Write-Host -ForegroundColor Yellow 'Verify the Date and Time is set properly including the Time Zone'
        Write-Host -ForegroundColor Yellow 'If this is not configured properly, Certificates and Domain Join may fail'
        Start-Process 'ms-settings:dateandtime' | Out-Null
        $ProcessId = (Get-Process -Name 'SystemSettings').Id
        if ($ProcessId) {
            Wait-Process $ProcessId
        }
    }
}
function Step-oobeExecutionPolicy {
    [CmdletBinding()]
    param ()
    if ($env:UserName -eq 'defaultuser0') {
        if ((Get-ExecutionPolicy) -ne 'RemoteSigned') {
            Write-Host -ForegroundColor Cyan 'Set-ExecutionPolicy RemoteSigned'
            Set-ExecutionPolicy RemoteSigned -Force
        }
    }
}
function Step-oobePackageManagement {
    [CmdletBinding()]
    param ()
    if ($env:UserName -eq 'defaultuser0') {
        if (Get-Module -Name PowerShellGet -ListAvailable | Where-Object {$_.Version -ge '2.2.5'}) {
            Write-Host -ForegroundColor Cyan 'PowerShellGet 2.2.5 or greater is installed'
        }
        else {
            Write-Host -ForegroundColor Cyan 'Install-Package PackageManagement,PowerShellGet'
            Install-Package -Name PowerShellGet -MinimumVersion 2.2.5 -Force -Confirm:$false -Source PSGallery | Out-Null
    
            Write-Host -ForegroundColor Cyan 'Import-Module PackageManagement,PowerShellGet'
            Import-Module PackageManagement,PowerShellGet -Force
        }
    }
}
function Step-oobeTrustPSGallery {
    [CmdletBinding()]
    param ()
    if ($env:UserName -eq 'defaultuser0') {
        $PSRepository = Get-PSRepository -Name PSGallery
        if ($PSRepository)
        {
            if ($PSRepository.InstallationPolicy -ne 'Trusted')
            {
                Write-Host -ForegroundColor Cyan 'Set-PSRepository PSGallery Trusted'
                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
            }
        }
    }
}


function Step-oobeRemoveAppxPackage {
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeRemoveAppxPackage -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Removing Appx Packages'
        foreach ($Item in $Global:oobeCloud.oobeRemoveAppxPackageName) {
            if (Get-Command Get-AppxProvisionedPackage) {
                Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -Match $Item} | ForEach-Object {
                    Write-Host -ForegroundColor DarkGray $_.DisplayName
                    if ((Get-Command Remove-AppxProvisionedPackage).Parameters.ContainsKey('AllUsers')) {
                        Try
                        {
                            $null = Remove-AppxProvisionedPackage -Online -AllUsers -PackageName $_.PackageName
                        }
                        Catch
                        {
                            Write-Warning "AllUsers Appx Provisioned Package $($_.PackageName) did not remove successfully"
                        }
                    }
                    else {
                        Try
                        {
                            $null = Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName
                        }
                        Catch
                        {
                            Write-Warning "Appx Provisioned Package $($_.PackageName) did not remove successfully"
                        }
                    }
                }
            }
        }
    }
}
function Step-Update-WindowsStoreApps {
    [CmdletBinding()]
    param()

    # Check for Administrator Privileges
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "Administrator privileges are required to install winget and update applications."
        Write-Warning "Please re-run this script as an Administrator."
        return
    } else {
        Write-Host "Running with Administrator privileges." -ForegroundColor Green
    }

    # Check if winget is installed
    Write-Host "Checking for winget..."
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue

    if ($null -eq $wingetCmd) {
        Write-Host "winget not found. Attempting to download and install winget..."

        $wingetReleaseUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $tempPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller.msixbundle"

        try {
            Write-Host "Downloading winget installer from $wingetReleaseUrl..."
            Invoke-WebRequest -Uri $wingetReleaseUrl -OutFile $tempPath -UseBasicParsing -Verbose:$false
            Write-Host "Download complete."

            Write-Host "Installing winget (App Installer)..."
            # Suppress progress bar for Add-AppxPackage for cleaner output
            $ProgressPreference = 'SilentlyContinue'
            Add-AppxPackage -Path $tempPath | Out-Null
            $ProgressPreference = 'Continue' # Reset preference

            Write-Host "Winget (App Installer) installation attempted."

            # Attempt to find winget again after installation
            $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
            if ($null -eq $wingetCmd) {
                Write-Warning "Winget has been installed, but the 'winget' command might not be available in this current PowerShell session yet."
                Write-Warning "Please try opening a NEW PowerShell terminal and running 'Update-WindowsStoreApps' again."
                Write-Warning "You can also verify the installation by typing 'winget --version' in a new terminal."
                return # Exit function as winget is not yet usable in this session
            } else {
                Write-Host "Winget is now installed and available at: $($wingetCmd.Source)" -ForegroundColor Green
            }
        } catch {
            Write-Error "Failed to download or install winget: $($_.Exception.Message)"
            if (Test-Path $tempPath) {
                Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
            }
            return
        } finally {
            if (Test-Path $tempPath) {
                Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
                Write-Host "Cleaned up downloaded installer file."
            }
        }
    } else {
        Write-Host "Winget is already installed at: $($wingetCmd.Source)" -ForegroundColor Green
    }

    # Proceed to update Store apps using winget
    Write-Host "Attempting to update all Microsoft Store apps using winget."
    Write-Host "This process may take some time. Please wait..."

    try {
        # Arguments for winget
        $arguments = "upgrade --all --source msstore --accept-package-agreements --accept-source-agreements --disable-interactivity"
        Write-Host "Executing: winget $arguments"

        # Using Start-Process to better handle CLI tool execution and output
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = $wingetCmd.Source # Use the full path to winget
        $processInfo.Arguments = $arguments
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false   # Required for redirecting IO streams
        $processInfo.CreateNoWindow = $true     # Run silently in the background

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        
        $process.Start() | Out-Null # Start the process

        # Capture output
        $stdout = $process.StandardOutput.ReadToEnd()
        $stderr = $process.StandardError.ReadToEnd()

        $process.WaitForExit() # Wait for the process to complete

        Write-Host "----- Winget Output -----" -ForegroundColor Cyan
        if ($stdout) {
            Write-Host $stdout
        } else {
            Write-Host "(No standard output)"
        }
        
        if ($stderr) {
            Write-Warning "----- Winget Errors -----"
            Write-Warning $stderr
        }

        if ($process.ExitCode -eq 0) {
            Write-Host "Winget update process completed successfully." -ForegroundColor Green
        } else {
            Write-Warning "Winget update process finished with Exit Code: $($process.ExitCode)."
            Write-Warning "Review the output above for any errors or issues."
        }

    } catch {
        Write-Error "An error occurred while trying to run winget upgrade: $($_.Exception.Message)"
    }

    Write-Host "Function Update-WindowsStoreApps finished."
}



function Step-oobeAddCapability {
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeAddCapability -eq $true)) {
        Write-Host -ForegroundColor Cyan "Add-WindowsCapability"
        foreach ($Item in $Global:oobeCloud.oobeAddCapabilityName) {
            $WindowsCapability = Get-WindowsCapability -Online -Name "*$Item*" -ErrorAction SilentlyContinue | Where-Object {$_.State -ne 'Installed'}
            if ($WindowsCapability) {
                foreach ($Capability in $WindowsCapability) {
                    Write-Host -ForegroundColor DarkGray $Capability.DisplayName
                    $Capability | Add-WindowsCapability -Online | Out-Null
                }
            }
        }
    }
}
function Step-oobeUpdateDrivers {
    [CmdletBinding()]
    param ()
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeUpdateDrivers -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Updating Windows Drivers'
        if (!(Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore)) {
            try {
                Install-Module PSWindowsUpdate -Force
                Import-Module PSWindowsUpdate -Force
            }
            catch {
                Write-Warning 'Unable to install PSWindowsUpdate Driver Updates'
            }
        }
        if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
            Start-Process PowerShell.exe -ArgumentList "-Command Install-WindowsUpdate -UpdateType Driver -AcceptAll -IgnoreReboot" -Wait
        }
    }
}
function Step-oobeUpdateWindows {
    [CmdletBinding()]
    param ()
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeUpdateWindows -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Updating Windows'
        if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
            try {
                Install-Module PSWindowsUpdate -Force
                Import-Module PSWindowsUpdate -Force
            }
            catch {
                Write-Warning 'Unable to install PSWindowsUpdate Windows Updates'
            }
        }
        if (Get-Module PSWindowsUpdate -ListAvailable -ErrorAction Ignore) {
            #Write-Host -ForegroundColor DarkCyan 'Add-WUServiceManager -MicrosoftUpdate -Confirm:$false'
            Add-WUServiceManager -MicrosoftUpdate -Confirm:$false | Out-Null
            #Write-Host -ForegroundColor DarkCyan 'Install-WindowsUpdate -UpdateType Software -AcceptAll -IgnoreReboot'
            #Install-WindowsUpdate -UpdateType Software -AcceptAll -IgnoreReboot -NotTitle 'Malicious'
            #Write-Host -ForegroundColor DarkCyan 'Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot'
            Start-Process PowerShell.exe -ArgumentList "-Command Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotTitle 'Preview' -NotKBArticleID 'KB890830','KB5005463','KB4481252'" -Wait
        }
    }
}

function Step-oobeRestartComputer {
    [CmdletBinding()]
    param ()
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeRestartComputer -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Build Complete!'
        Write-Warning 'Device will restart in 30 seconds.  Press Ctrl + C to cancel'
        Stop-Transcript
        Start-Sleep -Seconds 30
        Restart-Computer
    }
}
function Step-oobeStopComputer {
    [CmdletBinding()]
    param ()
    if (($env:UserName -eq 'defaultuser0') -and ($Global:oobeCloud.oobeStopComputer -eq $true)) {
        Write-Host -ForegroundColor Cyan 'Build Complete!'
        Write-Warning 'Device will shutdown in 30 seconds. Press Ctrl + C to cancel'
        Stop-Transcript
        Start-Sleep -Seconds 30
        Stop-Computer
    }
}


#endregion

# Execute functions
Step-KeyboardLanguage
Step-oobeExecutionPolicy
Step-oobePackageManagement
Step-oobeTrustPSGallery
Step-oobeSetDisplay
Step-oobeSetRegionLanguage
Step-oobeSetDateTime
Step-oobeRemoveAppxPackage
Step-Update-WindowsStoreApps
Step-oobeAddCapability
Step-oobeUpdateDrivers
Step-oobeUpdateWindows
Step-oobeRestartComputer
Step-oobeStopComputer
#=================================================
