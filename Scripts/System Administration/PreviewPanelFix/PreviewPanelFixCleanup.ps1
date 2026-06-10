#Requires -Version 3.0
# Cleans up entries written by PreviewPanelFix.
#
# Usage:
#   .\PreviewPanelFixCleanup.ps1         - remove bad Ranges entries only
#   .\PreviewPanelFixCleanup.ps1 -Reset  - also remove Domains entries (full wipe, re-run fix after)

param(
    [switch]$Reset
)

$RangesReg  = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges'
$DomainsReg = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'
$DomainsPSH = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'

Write-Host ''
Write-Host 'PreviewPanelFix - Cleanup' -ForegroundColor Cyan
Write-Host '-------------------------' -ForegroundColor Cyan
if ($Reset) { Write-Host '  (Reset mode - Domains entries will also be removed)' -ForegroundColor Yellow }
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

# --- Remove Domains entries (Reset mode only) ---
if ($Reset) {
    Write-Host ''
    Write-Host 'Checking ZoneMap\Domains...' -ForegroundColor Cyan
    $removedDomains = 0
    $queryOut = & reg query $DomainsReg 2>&1
    foreach ($line in $queryOut) {
        if ($line -match '\\([^\\\s]+)\s*$') {
            $subkey  = $Matches[1]
            $fullKey = "$DomainsReg\$subkey"
            $valOut  = & reg query $fullKey /v file 2>&1
            if ($valOut -match '\*\s+REG_DWORD\s+0x1') {
                & reg delete $fullKey /f 2>&1 | Out-Null
                Write-Host "  REMOVED  $subkey" -ForegroundColor Green
                $removedDomains++
            }
        }
    }
    if ($removedDomains -eq 0) {
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
