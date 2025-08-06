
# PowerShell Script: Monitor NIC Resets and Export Logs on Trigger
# Save as: Monitor-NIC-Resets.ps1

$WatchProvider = "TheNameOfYourNIC"  # Change if you use a different NIC driver
$EventIDs = @(7021, 16384, 16394)
$ExportPath = "$env:USERPROFILE\Desktop\NIC_Disconnect_Logs"
$SystemLogExport = Join-Path $ExportPath "SystemLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').evtx"
$NicStatsExport = Join-Path $ExportPath "NICStats_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Create export folder if missing
if (!(Test-Path $ExportPath)) {
    New-Item -ItemType Directory -Path $ExportPath | Out-Null
}

Write-Host "Monitoring NIC events... Press Ctrl+C to stop.`n"

while ($true) {
    $events = Get-WinEvent -LogName System -MaxEvents 20 |
        Where-Object {
            $EventIDs -contains $_.Id -and
            $_.ProviderName -like "*$WatchProvider*"
        }

    if ($events) {
        Write-Host "`n[!] NIC Event Detected at $(Get-Date). Exporting logs..."

        # Export full system log
        wevtutil epl System $SystemLogExport

        # Save NIC stats
        Get-NetAdapterStatistics | Out-File -FilePath $NicStatsExport

        Write-Host "Logs saved to: $ExportPath`n"
        break
    }

    Start-Sleep -Seconds 10
}
