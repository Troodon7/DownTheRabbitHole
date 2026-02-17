
# =========================
# 🔍 DOWNLOADS MONITORING SCRIPT - WITH FIXES
# =========================

# CONFIGURATION
$downloadsPath = "$env:USERPROFILE\Downloads"
$logFile = "$env:USERPROFILE\\Desktop\Downloads_ActivityLog.txt"
$hashAlgo = "SHA256"

# Regex patterns to flag suspicious patterns (customize as needed)
$patternWatchList = @(
    "^suspicious.*\.exe$",
    "^invoice\d{1,3}\.pdf$",
    "^doc\d+\.zip$"
)

# 🛠 Ensure logging directory exists
if (!(Test-Path -Path (Split-Path $logFile))) {
    New-Item -ItemType Directory -Path (Split-Path $logFile) -Force | Out-Null
}

# 🔒 Global references to keep watcher and events alive
$global:fsw = $null
$global:eventCreated = $null
$global:eventChanged = $null

# 🔧 Logging function
function Log-Event {
    param ([string]$message)
    Add-Content -Path $logFile -Value ("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $message)
}

# 🧮 Hash helper
function Get-FileHashSafe {
    param([string]$path)
    try {
        return (Get-FileHash -Algorithm $hashAlgo -Path $path).Hash
    } catch {
        return "N/A"
    }
}

# 🌐 Zone identifier (download origin)
function Get-ZoneIdentifier {
    param([string]$path)
    $ads = "$path`:Zone.Identifier"
    if (Test-Path $ads) {
        try {
            return Get-Content $ads -ErrorAction Stop | Out-String
        } catch {
            return "Error reading ADS"
        }
    } else {
        return "No ADS"
    }
}

# 🔍 Regex pattern matcher
function MatchesWatchPattern {
    param ([string]$filename)
    foreach ($pattern in $patternWatchList) {
        if ($filename -match $pattern) { return $pattern }
    }
    return $null
}

# 🌐 Browser activity
function Get-BrowserProcesses {
    $browsers = @("chrome", "msedge", "firefox", "iexplore", "opera")
    return Get-Process | Where-Object { $browsers -contains $_.ProcessName }
}

function Find-RecentBrowserActivity {
    $recent = Get-Date
    $browsers = Get-BrowserProcesses | Where-Object { ($recent - $_.StartTime).TotalMinutes -lt 3 }

    if ($browsers.Count -gt 0) {
        Log-Event " - Recent Browser Activity:"
        foreach ($proc in $browsers) {
            Log-Event "   -> $($proc.ProcessName) (PID $($proc.Id)) - Started $($proc.StartTime)"
        }
    } else {
        Log-Event " - No browser process activity in the past 3 minutes."
    }
}

# 🧬 PID chain tracing
function Get-ParentProcessInfo {
    param ([int]$pid)

    try {
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $pid"
        $info = @()
        while ($proc -ne $null -and $proc.ProcessId -ne 0) {
            $info += " -> $($proc.Name) (PID $($proc.ProcessId))"
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.ParentProcessId)"
        }
        return ($info -join "`n")
    } catch {
        return "Error retrieving parent PID chain."
    }
}

# 🎯 Event handler logic
$handler = {
    Start-Sleep -Milliseconds 500

    $path = $Event.SourceEventArgs.FullPath
    $fileName = [System.IO.Path]::GetFileName($path)

    if (Test-Path $path) {
        $fileInfo = Get-Item $path
        $hash = Get-FileHashSafe -path $path
        $zone = Get-ZoneIdentifier -path $path
        $matchPattern = MatchesWatchPattern -filename $fileName

        Log-Event "NEW FILE EVENT: $fileName"
        Log-Event " - Path: $path"
        Log-Event " - Size: $($fileInfo.Length) bytes"
        Log-Event " - Extension: $($fileInfo.Extension)"
        Log-Event " - SHA256: $hash"
        Log-Event " - Zone Identifier: $zone"

        if ($matchPattern) {
            Log-Event " ⚠️  Matched suspicious pattern: $matchPattern"
        }

        # TCP connections
        $netConns = Get-NetTCPConnection | Where-Object { $_.State -eq "Established" }
        if ($netConns) {
            Log-Event " - Active TCP Connections:"
            foreach ($conn in $netConns) {
                Log-Event "   -> $($conn.LocalAddress):$($conn.LocalPort) -> $($conn.RemoteAddress):$($conn.RemotePort) [$($conn.OwningProcess)]"
            }
        } else {
            Log-Event " - No active TCP connections."
        }

        # Top processes
        $procs = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
        Log-Event " - Top Processes by CPU:"
        foreach ($p in $procs) {
            Log-Event "   -> $($p.ProcessName) (PID $($p.Id)) - CPU: $($p.CPU)"
        }

        # Browser & PID tree
        Find-RecentBrowserActivity
        Log-Event " - Parent PID Chains (sampling):"
        $allPIDs = Get-Process | Select-Object -ExpandProperty Id
        foreach ($pid in $allPIDs) {
            $trace = Get-ParentProcessInfo -pid $pid
            if ($trace -match "chrome|msedge|firefox") {
                Log-Event $trace
            }
        }

        Log-Event "---------------------------"
    }
}

# 🖥 Watcher Setup
$global:fsw = New-Object System.IO.FileSystemWatcher
$global:fsw.Path = $downloadsPath
$global:fsw.Filter = "*.*"
$global:fsw.IncludeSubdirectories = $false
$global:fsw.EnableRaisingEvents = $true

$global:eventCreated = Register-ObjectEvent $global:fsw 'Created' -Action $handler
$global:eventChanged = Register-ObjectEvent $global:fsw 'Changed' -Action $handler

Log-Event "✅ Monitoring started on $downloadsPath. Log file: $logFile"
Write-Host "Monitoring started. Press Ctrl+C to exit."

while ($true) { Start-Sleep -Seconds 1 }
