# Define your company prefix
$company = "Arivo"

# Get the device serial number
$serial = (Get-WmiObject -Class Win32_BIOS).SerialNumber.Trim()

# Combine into new hostname
$newName = "$company-$serial"

# Rename the computer
Rename-Computer -NewName $newName -Force
