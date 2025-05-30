
function Set-ArivoComputerName {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        # No parameters are defined for this function as it operates automatically
    )

    # Check for Administrator Privileges
    $currentUser = New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not ($currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        Write-Error "Administrator privileges are required to rename the computer. Please run PowerShell as an Administrator."
        return # Exit the function if not admin
    }

    # 1. Get the device's serial number
    $SerialNumber = $null
    try {
        $SerialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
        if ([string]::IsNullOrWhiteSpace($SerialNumber)) {
            Write-Error "Could not retrieve a valid serial number for the device. Computer will not be renamed."
            return
        }
        $SerialNumber = $SerialNumber.Trim() # Remove any leading/trailing whitespace
    }
    catch {
        Write-Error "Failed to retrieve device serial number. Error: $($_.Exception.Message). Computer will not be renamed."
        return
    }

    # 2. Construct the new computer name
    # Using "Arivo-" as hostnames typically don't contain spaces.
    $NewComputerName = "Arivo-$($SerialNumber)"

    # Validate the constructed name (optional, as Rename-Computer will also validate)
    # Check for total length (DNS hostname label max 63 chars, NetBIOS max 15 chars - Windows truncates NetBIOS automatically)
    if ($NewComputerName.Length -gt 63) {
        Write-Warning "The generated computer name '$NewComputerName' is longer than 63 characters and might be problematic. Consider a shorter prefix or serial number handling if this occurs."
    }
    if ($NewComputerName -match '[^a-zA-Z0-9-]') {
         Write-Warning "The generated computer name '$NewComputerName' contains characters other than alphanumeric and hyphens. This might be an issue or get sanitized by the system."
    }

    $CurrentComputerName = $env:COMPUTERNAME
    Write-Host "Current computer name: $CurrentComputerName"
    Write-Host "Retrieved Serial Number: $SerialNumber"
    Write-Host "Desired new computer name: $NewComputerName"

    if ($NewComputerName -eq $CurrentComputerName) {
        Write-Warning "The desired new name '$NewComputerName' is the same as the current computer name. No renaming action will be taken."
        return
    }

    # 3. Rename the computer
    try {
        $renameParams = @{
            NewName     = $NewComputerName
            ErrorAction = 'Stop'
            Force       = $true # Suppresses Rename-Computer's own confirmation prompts
        }

        $actionMessage = "Rename computer from '$CurrentComputerName' to '$NewComputerName'. A manual restart will be required for the change to take full effect."

        if ($PSCmdlet.ShouldProcess($CurrentComputerName, $actionMessage)) {
            Rename-Computer @renameParams
            
            Write-Host "Computer name has been changed to '$NewComputerName' in the registry."
            Write-Warning "A restart is required for the new name to take full effect."
        } else {
            Write-Host "Rename operation for computer '$CurrentComputerName' to '$NewComputerName' was cancelled by the user or due to -WhatIf."
        }
    }
    catch {
        Write-Error "Failed to rename the computer to '$NewComputerName'. Error: $($_.Exception.Message)"
    }
}

Set-ArivoComputerName
# --- How to use the function ---

# To make the function available in your script or session:
# 1. Copy and paste the entire function code above into the beginning of your script, or into your PowerShell profile.
# 2. Or, save it as a .ps1 file (e.g., MyCustomFunctions.ps1) and dot-source it in your main script:
#    . C:\Path\To\Your\Scripts\MyCustomFunctions.ps1

# Now you can call the function at the end of your script.
# A manual restart will always be necessary for the change to apply.

# Example 1: Rename the computer to "Arivo-SERIALNUMBER".
# You will need to restart the computer manually afterwards.
# Set-ArivoComputerName

# Example 2: See what the function would do without actually renaming (useful for testing)
# Set-ArivoComputerName -WhatIf

# Example 3: Prompts for confirmation before renaming
# Set-ArivoComputerName -Confirm
