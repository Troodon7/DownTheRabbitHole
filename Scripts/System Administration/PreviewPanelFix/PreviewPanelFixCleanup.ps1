#Requires -Version 3.0
# Cleans up entries written by PreviewPanelFix.
#
# Usage:
#   .\PreviewPanelFixCleanup.ps1         - remove legacy bad entries only (safe)
#   .\PreviewPanelFixCleanup.ps1 -Reset  - remove entries for current mapped drives only

param(
    [switch]$Reset
)

$RangesReg  = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges'
$DomainsReg = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'

# --- Detect current mapped drive servers (same logic as main script) ---
function Get-MappedServers {
    $servers  = @{}
    $uncPaths = @()

    try {
        $regDrives = Get-ChildItem 'HKCU:\Network' -ErrorAction SilentlyContinue
        foreach ($drive in $regDrives) {
            $remote = (Get-ItemProperty -Path $drive.PSPath -ErrorAction SilentlyContinue).RemotePath
            if ($remote) { $uncPaths += $remote }
        }
    } catch {}
    try {
        Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayRoot -like '\\*' } |
            ForEach-Object { if ($_.DisplayRoot -notin $uncPaths) { $uncPaths += $_.DisplayRoot } }
    } catch {}
    try {
        Get-SmbMapping -ErrorAction SilentlyContinue |
            ForEach-Object { if ($_.RemotePath -notin $uncPaths) { $uncPaths += $_.RemotePath } }
    } catch {}
    try {
        (& net use 2>&1) | ForEach-Object {
            if ($_ -match '(\\\\[^\s]+)' -and $Matches[1] -notin $uncPaths) { $uncPaths += $Matches[1] }
        }
    } catch {}

    foreach ($unc in $uncPaths) {
        if ($unc -match '^\\\\([^\\]+)') {
            $s = $Matches[1]
            if (-not $servers.ContainsKey($s)) { $servers[$s] = $unc }
        }
    }
    return $servers
}

Write-Host ''
Write-Host 'PreviewPanelFix - Cleanup' -ForegroundColor Cyan
Write-Host '-------------------------' -ForegroundColor Cyan
Write-Host ''

# --- Remove legacy bad entries (old <ip> format from early script versions) ---
Write-Host 'Checking for legacy bad entries...' -ForegroundColor Cyan
$removedLegacy = 0
$queryOut = & reg query $RangesReg 2>&1
foreach ($line in $queryOut) {
    if ($line -match '\\(Range\d+)\s*$') {
        $fullKey  = "$RangesReg\$($Matches[1])"
        $valueOut = & reg query $fullKey /v '<ip>' 2>&1
        if ($valueOut -match '<ip>') {
            $ip = ($valueOut | Select-String '<ip>') -replace '.*<ip>\s+\S+\s+', ''
            & reg delete $fullKey /f 2>&1 | Out-Null
            Write-Host "  REMOVED  $($Matches[1])  (legacy entry, was: $($ip.Trim()))" -ForegroundColor Green
            $removedLegacy++
        }
    }
}
if ($removedLegacy -eq 0) { Write-Host '  Nothing to clean up.' -ForegroundColor DarkGray }

# --- Reset: remove only entries matching current mapped drives ---
if ($Reset) {
    $servers = Get-MappedServers

    if ($servers.Count -eq 0) {
        Write-Host ''
        Write-Host 'No mapped drives found - nothing to reset.' -ForegroundColor Yellow
    } else {
        Write-Host ''
        Write-Host "Resetting entries for $($servers.Count) mapped drive server(s)..." -ForegroundColor Cyan
        $removedReset = 0

        foreach ($entry in $servers.GetEnumerator()) {
            $server = $entry.Key
            $isIP   = $server -match '^\d{1,3}(\.\d{1,3}){3}$'

            if ($isIP) {
                # Find and remove the matching RangeN entry
                $queryOut = & reg query $RangesReg 2>&1
                foreach ($line in $queryOut) {
                    if ($line -match '\\(Range\d+)\s*$') {
                        $fullKey  = "$RangesReg\$($Matches[1])"
                        $rangeOut = & reg query $fullKey /v ':Range' 2>&1
                        if ($rangeOut -match [regex]::Escape($server)) {
                            & reg delete $fullKey /f 2>&1 | Out-Null
                            Write-Host "  REMOVED  $server  ($($Matches[1]))" -ForegroundColor Green
                            $removedReset++
                            break
                        }
                    }
                }
            } else {
                # Remove the matching Domains entry
                $valOut = & reg query "$DomainsReg\$server" /v '*' 2>&1
                if ($valOut -match '\*\s+REG_DWORD\s+0x1') {
                    & reg delete "$DomainsReg\$server" /f 2>&1 | Out-Null
                    Write-Host "  REMOVED  $server" -ForegroundColor Green
                    $removedReset++
                }
            }
        }

        if ($removedReset -eq 0) { Write-Host '  Nothing to clean up.' -ForegroundColor DarkGray }
    }
}

# --- Show remaining entries ---
Write-Host ''
Write-Host 'Remaining ZoneMap\Ranges entries:' -ForegroundColor Cyan
$found = 0
$queryOut = & reg query $RangesReg 2>&1
foreach ($line in $queryOut) {
    if ($line -match '\\(Range\d+)\s*$') {
        $fullKey  = "$RangesReg\$($Matches[1])"
        $rangeOut = & reg query $fullKey /v ':Range' 2>&1
        if ($rangeOut -notmatch 'ERROR') {
            $ip = ($rangeOut | Select-String ':Range') -replace '.*:Range\s+\S+\s+', ''
            Write-Host "  $($Matches[1])  $($ip.Trim())" -ForegroundColor Green
            $found++
        }
    }
}
if ($found -eq 0) { Write-Host '  (none)' -ForegroundColor DarkGray }

Write-Host ''
Write-Host 'Done. Close and reopen Internet Options to confirm.' -ForegroundColor Cyan
if ($Reset) { Write-Host 'Run PreviewPanelFix.bat to re-add entries.' -ForegroundColor DarkGray }
