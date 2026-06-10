#Requires -Version 3.0
# Removes bad ZoneMap\Ranges entries written by an earlier version of Preview Panel Fix.
# Those entries show as ":Range:" with a square character in the Local Intranet Sites UI.
# Safe to run multiple times.

$RangesPath  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges'
$DomainsPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'

Write-Host ''
Write-Host 'Preview Panel Fix - Cleanup' -ForegroundColor Cyan
Write-Host '---------------------------' -ForegroundColor Cyan
Write-Host ''

# Remove bad Ranges entries - use GetValueNames() to safely read angle-bracket value names
$removed = 0
try {
    $ranges = Get-ChildItem $RangesPath -ErrorAction SilentlyContinue
    foreach ($range in $ranges) {
        try {
            $key = Get-Item -Path $range.PSPath -ErrorAction SilentlyContinue
            if ($key -and ($key.GetValueNames() -contains '<ip>')) {
                $ip = $key.GetValue('<ip>')
                Remove-Item -Path $range.PSPath -Force
                Write-Host "  REMOVED  $($range.PSChildName)  (was: $ip)" -ForegroundColor Green
                $removed++
            }
        } catch {}
    }
} catch {
    Write-Host "  ERROR reading Ranges: $_" -ForegroundColor Red
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
Write-Host 'Done.' -ForegroundColor Cyan
