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
    try {
        $domains = Get-ChildItem $DomainsPSH -ErrorAction SilentlyContinue
        foreach ($d in $domains) {
            $val = Get-ItemProperty -Path $d.PSPath -Name 'file' -ErrorAction SilentlyContinue
            if ($val -and $val.file -eq 1) {
                & reg delete "$DomainsReg\$($d.PSChildName)" /f 2>&1 | Out-Null
                Write-Host "  REMOVED  $($d.PSChildName)" -ForegroundColor Green
                $removedDomains++
            }
        }
    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
    }
    if ($removedDomains -eq 0) {
        Write-Host '  Nothing to clean up.' -ForegroundColor DarkGray
    }
}

# --- Show remaining Domains entries ---
Write-Host ''
Write-Host 'Remaining ZoneMap\Domains entries (file=1):' -ForegroundColor Cyan
try {
    $domains = Get-ChildItem $DomainsPSH -ErrorAction SilentlyContinue
    $found = 0
    foreach ($d in $domains) {
        $val = Get-ItemProperty -Path $d.PSPath -Name 'file' -ErrorAction SilentlyContinue
        if ($val -and $val.file -eq 1) {
            Write-Host "  $($d.PSChildName)" -ForegroundColor Green
            $found++
        }
    }
    if ($found -eq 0) { Write-Host '  (none)' -ForegroundColor DarkGray }
} catch {
    Write-Host "  ERROR: $_" -ForegroundColor Red
}

Write-Host ''
Write-Host 'Done. Close and reopen Internet Options to confirm.' -ForegroundColor Cyan
if ($Reset) {
    Write-Host 'Run PreviewPanelFix.bat to re-add the correct entries.' -ForegroundColor DarkGray
}
