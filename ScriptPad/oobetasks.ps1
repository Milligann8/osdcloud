# oobe.osdcloud.ch - needs to be here for blog post on akosbakos.ch

[CmdletBinding()]
param()
#=================================================
#Script Information

#=================================================
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
    oobeRemoveAppxPackageName = 'CommunicationsApps','OfficeHub','People','Skype','Solitaire','Xbox','ZuneMusic','ZuneVideo'
    oobeUpdateDrivers = $true
    oobeUpdateWindows = $true
    oobeRestartComputer = $true
    oobeStopComputer = $false
}

function Step-KeyboardLanguage {

    Write-Host -ForegroundColor Green "Set keyboard language to en-US"
    Start-Sleep -Seconds 5
    
    $LanguageList = Get-WinUserLanguageList
    
    $LanguageList.Add("en-US")
    Set-WinUserLanguageList $LanguageList -Force
    
    Start-Sleep -Seconds 5
    
    $LanguageList = Get-WinUserLanguageList
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
# C:\Windows\Setup\Scripts\oobe.ps1

function Rename-ComputerWithSerialNumber {
    <#
    .SYNOPSIS
        Renames the computer using the prefix "arivo-" followed by the system's serial number.
        Optionally restarts the computer after renaming.
    .DESCRIPTION
        This function retrieves the serial number of the computer using WMI,
        constructs a new computer name with the "arivo-" prefix, renames the computer,
        and optionally restarts the system.
    #>
    param (
        [Switch]$Restart = $false
    )

    # Set PowerShell Execution Policy if needed
    Set-ExecutionPolicy Bypass -Scope LocalMachine -Force -ErrorAction SilentlyContinue

    try {
        # Get the Serial Number
        $SerialNumber = Get-WmiObject Win32_BIOS | Select-Object -ExpandProperty SerialNumber
        if (-not $SerialNumber) {
            Write-Warning "Could not retrieve serial number. Skipping computer renaming."
            return
        }

        # Define the new Computer Name
        $NewComputerName = "arivo-$SerialNumber"

        # Rename the Computer
        Write-Host "Renaming computer to '$NewComputerName'..."
        Rename-Computer -NewName $NewComputerName -Force

        if ($Restart) {
            Write-Host "Restarting computer to apply the new name..."
            Restart-Computer -Force
        } else {
            Write-Host "Computer renamed successfully. A restart is required for the new name to take effect."
        }
    } catch {
        Write-Error "An error occurred during computer renaming: $($_.Exception.Message)"
    }
}


# C:\Windows\Setup\Scripts\oobe.ps1

function Generate-UnattendXML {
    <#
    .SYNOPSIS
        Generates the unattend.xml content as a string.
    .DESCRIPTION
        This function creates the XML content for the unattend.xml file,
        including settings for autologon, user accounts, OOBE skipping, and timezone.
    .EXAMPLE
        $xmlContent = Generate-UnattendXML
    #>
    [CmdletBinding()]
    param ()

    $xmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"
          xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="en-US" versionScope="nonSxS">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <ComputerName>TEMP-OOBE</ComputerName>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <AutoLogon>
                <Password>
                    <Value>Test</Value>
                    <PlainText>false</PlainText>
                </Password>
                <Enabled>true</Enabled>
                <LogonCount>1</LogonCount>
                <Username>ariadmin</Username>
            </AutoLogon>
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Name>ariadmin</Name>
                        <Group>Administrators</Group>
                        <Password>
                            <Value>Test</Value>
                            <PlainText>false</PlainText>
                        </Password>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
            </OOBE>
            <TimeZone>Mountain Standard Time</TimeZone>
        </component>
    </settings>
</unattend>
"@
    return $xmlContent
}

function Apply-Unattend {
    <#
    .SYNOPSIS
        Generates the unattend.xml and moves it to C:\Windows\Panther\.
    .DESCRIPTION
        This function calls Generate-UnattendXML to create the XML content,
        outputs it to a temporary file, and then moves it to the Windows Panther directory.
        It does NOT initiate a system reboot.
    #>
    [CmdletBinding()]
    param ()

    $xmlContent = Generate-UnattendXML
    $TempUnattendPath = "C:\Windows\Temp\unattend.xml"
    $DestinationPath = "C:\Windows\Panther\unattend.xml"

    try {
        Write-Host "Generating unattend.xml to '$TempUnattendPath'..."
        $xmlContent | Out-File -FilePath $TempUnattendPath -Encoding utf8 -Width 2000 -Force -ErrorAction Stop
        Write-Host "unattend.xml generated successfully."

        Write-Host "Moving unattend.xml to '$DestinationPath'..."
        Move-Item -Path $TempUnattendPath -Destination $DestinationPath -Force -ErrorAction Stop
        Write-Host "unattend.xml moved to C:\Windows\Panther\ successfully."
    }
    catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
    }
}

# Call the function to generate and apply the unattend.xml
Apply-Unattend

# Call the function to rename the computer and restart
#endregion

# Execute functions
Step-KeyboardLanguage
Step-oobeExecutionPolicy
Step-oobeTrustPSGallery
Step-oobeSetDisplay
Step-oobeSetRegionLanguage
Step-oobeSetDateTime
Step-oobePackageManagemen
Step-oobeRemoveAppxPackage
Step-oobeUpdateDrivers
Step-oobeUpdateWindows
Generate-UnattendXML
Rename-ComputerWithSerialNumber
Step-oobeRestartComputer
Step-oobeStopComputer
#=================================================
