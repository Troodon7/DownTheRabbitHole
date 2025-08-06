# Define the path for the log file
$LogFile = "C:\Logs\GPUpdateLog.txt"

# Ensure the log directory exists
$LogDirectory = Split-Path -Path $LogFile
if (!(Test-Path -Path $LogDirectory)) {
    New-Item -ItemType Directory -Path $LogDirectory | Out-Null
}

# List of computers (your provided list)
$Computers = @(
    "EXAMPLE-PC", "EXAMPLE-PC", "EXAMPLE-PC", "EXAMPLE-PC", "EXAMPLE-PC",
    "EXAMPLE-PC", "EXAMPLE-PC"

# Function to log messages with timestamps
function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}

# Run GPUpdate on each computer
foreach ($Computer in $Computers) {
    Write-Log "Starting GPUpdate on $Computer..."
    try {
        Invoke-GPUpdate -Computer $Computer -Target "User" -Force -Boot
        Write-Log "Successfully initiated GPUpdate on $Computer."
    } catch {
        Write-Log "Failed to update $Computer. Error: $_"
    }
}
