#Requires -Version 3.0
# Cleans up entries written by PreviewPanelFix.
#
# Usage:
#   .\PreviewPanelFixCleanup.ps1         - remove legacy bad entries only (safe)
#   .\PreviewPanelFixCleanup.ps1 -Reset  - wipe ALL ZoneMap Ranges and Domains entries
#
# WARNING: -Reset removes ALL Local Intranet zone entries, not just ones added by
# PreviewPanelFix. Any sites you added manually will also be removed. Re-run
# PreviewPanelFix.bat afterwards to restore the mapped drive entries.

param(
    [switch]$Reset
)

$RangesReg  = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges'
$DomainsReg = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'
$DomainsPSH = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'

Write-Host ''
Write-Host 'PreviewPanelFix - Cleanup' -ForegroundColor Cyan
Write-Host '-------------------------' -ForegroundColor Cyan
if ($Reset) {
    Write-Host '  WARNING: Reset mode removes ALL Local Intranet zone entries,' -ForegroundColor Red
    Write-Host '  not just ones added by PreviewPanelFix. Manually added sites' -ForegroundColor Red
    Write-Host '  will also be removed. Run PreviewPanelFix.bat when done.' -ForegroundColor Red
}
Write-Host ''

# --- Remove bad Ranges entries ---
# Use reg.exe directly - PS registry provider chokes on angle-bracket value names
Write-Host 'Checking ZoneMap\Ranges...' -ForegroundColor Cyan
$removedRanges = 0
$queryOut = & reg query $RangesReg 2>&1
foreach ($line in $queryOut) {
    if ($line -match '\\(Range\d+)\s*$') {
        $rangeName = $Matches[1]
        $fullKey   = "$RangesReg\$rangeName"
        $valueOut  = & reg query $fullKey /v '<ip>' 2>&1
        if ($valueOut -match '<ip>') {
            $ip = ($valueOut | Select-String '<ip>') -replace '.*<ip>\s+\S+\s+', ''
            & reg delete $fullKey /f 2>&1 | Out-Null
            Write-Host "  REMOVED  $rangeName  (was: $($ip.Trim()))" -ForegroundColor Green
            $removedRanges++
        }
    }
}
if ($removedRanges -eq 0) {
    Write-Host '  Nothing to clean up.' -ForegroundColor DarkGray
}

# --- Remove Ranges and Domains entries (Reset mode only) ---
if ($Reset) {
    Write-Host ''
    Write-Host 'Checking ZoneMap\Ranges...' -ForegroundColor Cyan
    $removedReset = 0
    $queryOut = & reg query $RangesReg 2>&1
    foreach ($line in $queryOut) {
        if ($line -match '\\(Range\d+)\s*$') {
            $rangeName = $Matches[1]
            $fullKey   = "$RangesReg\$rangeName"
            $rangeOut  = & reg query $fullKey /v ':Range' 2>&1
            if ($rangeOut -notmatch 'ERROR') {
                $ip = ($rangeOut | Select-String ':Range') -replace '.*:Range\s+\S+\s+', ''
                & reg delete $fullKey /f 2>&1 | Out-Null
                Write-Host "  REMOVED  $rangeName  ($($ip.Trim()))" -ForegroundColor Green
                $removedReset++
            }
        }
    }

    Write-Host ''
    Write-Host 'Checking ZoneMap\Domains...' -ForegroundColor Cyan
    $queryOut = & reg query $DomainsReg 2>&1
    foreach ($line in $queryOut) {
        if ($line -match '\\([^\\\s]+)\s*$') {
            $subkey  = $Matches[1]
            $fullKey = "$DomainsReg\$subkey"
            $valOut  = & reg query $fullKey /v '*' 2>&1
            if ($valOut -match '\*\s+REG_DWORD\s+0x1') {
                & reg delete $fullKey /f 2>&1 | Out-Null
                Write-Host "  REMOVED  $subkey" -ForegroundColor Green
                $removedReset++
            }
        }
    }

    if ($removedReset -eq 0) {
        Write-Host '  Nothing to clean up.' -ForegroundColor DarkGray
    }
}

# --- Show remaining Domains entries ---
Write-Host ''
Write-Host 'Remaining ZoneMap\Domains entries (file=1):' -ForegroundColor Cyan
$found = 0
$queryOut = & reg query $DomainsReg 2>&1
foreach ($line in $queryOut) {
    if ($line -match '\\([^\\\s]+)\s*$') {
        $subkey  = $Matches[1]
        $fullKey = "$DomainsReg\$subkey"
        $valOut  = & reg query $fullKey /v file 2>&1
        if ($valOut -match '\*\s+REG_DWORD\s+0x1') {
            Write-Host "  $subkey" -ForegroundColor Green
            $found++
        }
    }
}
if ($found -eq 0) { Write-Host '  (none)' -ForegroundColor DarkGray }

Write-Host ''
Write-Host 'Done. Close and reopen Internet Options to confirm.' -ForegroundColor Cyan
if ($Reset) {
    Write-Host 'Run PreviewPanelFix.bat to re-add the correct entries.' -ForegroundColor DarkGray
}
