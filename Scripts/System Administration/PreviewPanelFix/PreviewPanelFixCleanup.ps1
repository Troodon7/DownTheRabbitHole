#Requires -Version 3.0
# Removes bad ZoneMap\Ranges entries written by an earlier version of Preview Panel Fix.
# Those entries show as ":Range:" with a square character in the Local Intranet Sites UI.
# Safe to run multiple times.

$RangesReg   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges'
$DomainsPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'

Write-Host ''
Write-Host 'PreviewPanelFix - Cleanup' -ForegroundColor Cyan
Write-Host '-------------------------' -ForegroundColor Cyan
Write-Host ''

# Use reg.exe directly - PowerShell registry provider chokes on angle-bracket value names
$removed = 0
$queryOut = & reg query $RangesReg 2>&1
foreach ($line in $queryOut) {
    if ($line -match '\\(Range\d+)\s*$') {
        $rangeName = $Matches[1]
        $fullKey   = "$RangesReg\$rangeName"
        $valueOut  = & reg query $fullKey /v '<ip>' 2>&1
        if ($valueOut -match '<ip>') {
            $ip = ($valueOut | Select-String '<ip>') -replace '.*<ip>\s+\S+\s+',''
            & reg delete $fullKey /f 2>&1 | Out-Null
            Write-Host "  REMOVED  $rangeName  (was: $($ip.Trim()))" -ForegroundColor Green
            $removed++
        }
    }
}

if ($removed -eq 0) {
    Write-Host '  Nothing to clean up in ZoneMap\Ranges.' -ForegroundColor DarkGray
}

# Show current valid Domains entries so user can verify
Write-Host ''
Write-Host 'Current ZoneMap\Domains entries (file=1):' -ForegroundColor Cyan
try {
    $domains = Get-ChildItem $DomainsPath -ErrorAction SilentlyContinue
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
    Write-Host "  ERROR reading Domains: $_" -ForegroundColor Red
}

Write-Host ''
Write-Host 'Done. Close and reopen Internet Options to confirm the entry is gone.' -ForegroundColor Cyan
