# Define the path for the reboot log
$LogFile = "C:\Logs\RebootLog.txt"

# Ensure the log directory exists
$LogDirectory = Split-Path -Path $LogFile
if (!(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory | Out-Null
}

# Original full list of computers
$Computers = @(
    "EXAMPLE-PC", "EXAMPLE-PC", "EXAMPLE-PC", "EXAMPLE-PC", "EXAMPLE-PC",
    "EXAMPLE-PC", "EXAMPLE-PC"
)

# Function to write logs with timestamp
function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}

# Reboot each computer
foreach ($Computer in $Computers) {
    Write-Log "Attempting to reboot $Computer..."
    try {
        Restart-Computer -ComputerName $Computer -Force -ErrorAction Stop
        Write-Log "Successfully issued reboot for $Computer."
    } catch {
        Write-Log "Failed to reboot $Computer. Error: $_"
    }
}
