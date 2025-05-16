<#
.SYNOPSIS
  Creates an unattend.xml file and copies it to the appropriate OOBE directory.

.DESCRIPTION
  This script takes XML content embedded within the script, saves it to a file
  named "unattend.xml", and then copies the file to the directory where Windows
  Setup looks for unattend files during the Out-of-Box Experience (OOBE).
  This allows for automated Windows installation and configuration.

.PARAMETER DestinationPath
  (Optional) The destination path where the unattend.xml file should be copied.
  If not provided, the script will attempt to use the default OOBE path
  "C:\Windows\Panther".

.INPUTS
  None. The XML content is embedded within the script as a string.

.OUTPUTS
  None. The script attempts to create a file and copy it, but does not
  return objects.  Status is indicated via Write-Host.

.NOTES
  * The script requires administrator privileges to copy the file to the
    OOBE directory.
  * The destination path may vary depending on the Windows version.
  * Error handling is included for file creation and copying.
  * The script checks if the destination directory exists before
    attempting to copy the file.
#>
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-unattend.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore
param (
  [Parameter(Mandatory = $false, HelpMessage = "The destination path for the unattend.xml file (optional).")]
  [string]$DestinationPath = "C:\Windows\Panther"  # Default OOBE path
)

#region Script Body

# Define the filename
$FileName = "unattend.xml"
$FullPath = Join-Path -Path $PSScriptRoot -ChildPath $FileName

# Embed the XML content directly within the script using a here-string
$XMLContent = @"
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="oobeSystem">
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <InputLocale>en-us</InputLocale>
      <SystemLocale>en-us</SystemLocale>
      <UILanguage>en-us</UILanguage>
      <UserLocale>en-us</UserLocale>
    </component>
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <AutoLogon>
        <Password>
          <Value>test</Value>
          <PlainText>false</PlainText>
        </Password>
        <Enabled>true</Enabled>
        <LogonCount>2</LogonCount>
        <Username>ariadmin</Username>
      </AutoLogon>
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <ProtectYourPC>3</ProtectYourPC>
      </OOBE>
      <UserAccounts>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password>
              <Value>test</Value>
              <PlainText>false</PlainText>
            </Password>
            <DisplayName>ariadmin</DisplayName>
            <Group>Administrators</Group>
            <Name>ariadmin</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
    </component>
  </settings>
  <cpi:offlineImage xmlns:cpi="urn:schemas-microsoft-com:cpi" cpi:source="wim:c:/install.wim#Windows 11 Pro"/>
</unattend>
"@  # Use @" "... "@ for multi-line strings

# Write the XML content to the file
try {
  Write-Host "Creating file: $($FullPath)" -ForegroundColor Green
  [IO.File]::WriteAllText($FullPath, $XMLContent)
  Write-Host "File $($FullPath) created successfully." -ForegroundColor Green
} catch {
  Write-Host "Error creating file $($FullPath): $($_.Exception.Message)" -ForegroundColor Red
  Exit 1  # Terminate the script on error
}

# Check if the destination directory exists
if (-not (Test-Path -Path $DestinationPath -PathType 'Container')) {
  Write-Host "Error: Destination directory '$DestinationPath' does not exist." -ForegroundColor Red
  Write-Host "Please ensure the directory exists or provide a valid DestinationPath." -ForegroundColor Red
  # Attempt to create the directory.
   try{
     New-Item -Path $DestinationPath -ItemType Directory -Force
     Write-Host "Created directory: $($DestinationPath)" -ForegroundColor Green
   }
   catch{
     Write-Host "Error creating directory: $($_.Exception)"
     Exit 1
   }
}

# Copy the file to the destination
try {
  Write-Host "Copying file to: $($DestinationPath)" -ForegroundColor Green
  Copy-Item -Path $FullPath -Destination $DestinationPath -Force
  Write-Host "File $($FileName) copied to $($DestinationPath) successfully." -ForegroundColor Green
} catch {
  Write-Host "Error copying file to $($DestinationPath): $($_.Exception.Message)" -ForegroundColor Red
  Exit 1  # Terminate the script on error
}

Stop-Transcript 
# Optionally, remove the temporary file
# try {
#     Remove-Item -Path $FullPath
#     Write-Host "Removed temporary file: $($FullPath)" -ForegroundColor Green
# } catch {
#     Write-Host "Error removing temporary file $($FullPath): $($_.Exception.Message)" -ForegroundColor Yellow
# }

#endregion
