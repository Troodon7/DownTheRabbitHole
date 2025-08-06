# Set the folder path you want to clean
$folderPath = "C:\Test delete\Delete inside"
# Set the age limit in days
$daysOld = 60
# Path to the log file
$logFile = "C:\deleted items.log"
# Calculate cutoff time
$cutoffDate = (Get-Date).AddDays(-$daysOld)

# Ensure log file is reset cleanly
if (Test-Path $logFile) {
    Clear-Content -Path $logFile -ErrorAction SilentlyContinue
} else {
    New-Item -Path $logFile -ItemType File -Force | Out-Null
}

# Start fresh log
"==== Cleanup Run: $(Get-Date) ====" | Out-File -FilePath $logFile -Encoding UTF8
"Cutoff date/time (CreationTime): $cutoffDate" | Out-File -Append -FilePath $logFile -Encoding UTF8

function Clear-OldItems {
    param (
        [string]$path,
        [datetime]$cutoff
    )

    if (Test-Path $path) {
        # Delete old files
        Get-ChildItem -Path $path -File -Recurse -Force | ForEach-Object {
            if ($_.CreationTime -lt $cutoff) {
                $entry = "File: $($_.FullName) (Created: $($_.CreationTime))"
                $entry | Out-File -Append -FilePath $logFile -Encoding UTF8
                Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
            }
        }

        # Delete old folders
        Get-ChildItem -Path $path -Directory -Recurse -Force | ForEach-Object {
            if ($_.CreationTime -lt $cutoff) {
                $entry = "Folder: $($_.FullName) (Created: $($_.CreationTime))"
                $entry | Out-File -Append -FilePath $logFile -Encoding UTF8
                Remove-Item -Path $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

    } else {
        "Path not found: $path" | Out-File -Append -FilePath $logFile -Encoding UTF8
    }
}

# Run the cleanup
Clear-OldItems -path $folderPath -cutoff $cutoffDate
