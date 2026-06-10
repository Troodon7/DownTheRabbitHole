#Requires -Version 3.0
# Adds mapped drive UNC servers to the Windows Local Intranet trusted zone.
# Fixes PDF and file preview failures in Windows Explorer on network shares.
# No admin rights required - changes are per-user (HKCU).
#
# Usage:
#   .\Preview Panel Fix.ps1           - apply changes
#   .\Preview Panel Fix.ps1 -WhatIf   - dry run, no changes written

param(
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$DomainsPath  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'
$RangesPath   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges'
$IntranetZone = 1

function Get-MappedDriveServers {
    $servers  = @{}
    $uncPaths = @()

    try {
        $uncPaths = (Get-SmbMapping -ErrorAction Stop).RemotePath
    } catch {
        $netLines = & net use 2>&1
        foreach ($line in $netLines) {
            if ($line -match '(\\\\[^\s]+)') {
                $uncPaths += $Matches[1]
            }
        }
    }

    foreach ($unc in $uncPaths) {
        if ($unc -match '^\\\\([^\\]+)') {
            $server = $Matches[1]
            if (-not $servers.ContainsKey($server)) {
                $servers[$server] = $unc
            }
        }
    }

    return $servers
}

function Add-HostnameToIntranet {
    param([string]$Hostname, [string]$UncPath)

    $keyPath  = Join-Path $DomainsPath $Hostname
    $existing = Get-ItemProperty -Path $keyPath -Name 'file' -ErrorAction SilentlyContinue

    if ($existing -and $existing.file -eq $IntranetZone) {
        Write-Host "  SKIP   $Hostname  ($UncPath) - already set" -ForegroundColor DarkGray
        return
    }

    if ($WhatIf) {
        Write-Host "  WOULD ADD  $Hostname  ($UncPath)" -ForegroundColor Cyan
        return
    }

    if (-not (Test-Path $keyPath)) {
        New-Item -Path $keyPath -Force | Out-Null
    }
    Set-ItemProperty -Path $keyPath -Name 'file' -Value $IntranetZone -Type DWord
    Write-Host "  ADDED  $Hostname  ($UncPath)" -ForegroundColor Green
}

function Add-IPToIntranet {
    param([string]$IP, [string]$UncPath)

    # Check if this IP already exists in any RangeN entry
    $ranges = Get-ChildItem -Path $RangesPath -ErrorAction SilentlyContinue
    foreach ($range in $ranges) {
        $ipVal    = Get-ItemProperty -Path $range.PSPath -Name '<ip>'    -ErrorAction SilentlyContinue
        $zoneVal  = Get-ItemProperty -Path $range.PSPath -Name ':Range'  -ErrorAction SilentlyContinue
        if ($ipVal -and $zoneVal -and $ipVal.'<ip>' -eq $IP -and $zoneVal.':Range' -eq $IntranetZone) {
            Write-Host "  SKIP   $IP  ($UncPath) - already set" -ForegroundColor DarkGray
            return
        }
    }

    if ($WhatIf) {
        Write-Host "  WOULD ADD  $IP  ($UncPath)" -ForegroundColor Cyan
        return
    }

    $n = 1
    while (Test-Path (Join-Path $RangesPath ('Range' + $n))) { $n++ }
    $newPath = Join-Path $RangesPath ('Range' + $n)

    New-Item -Path $newPath -Force | Out-Null
    Set-ItemProperty -Path $newPath -Name '<ip>'    -Value $IP            -Type String
    Set-ItemProperty -Path $newPath -Name ':Range'  -Value $IntranetZone  -Type DWord

    Write-Host "  ADDED  $IP  ($UncPath) -> Range$n" -ForegroundColor Green
}

# --- Main ---

$banner = 'Mapped Drive - Local Intranet Zone Fixer'
Write-Host ''
Write-Host $banner -ForegroundColor Cyan
Write-Host ('-' * $banner.Length) -ForegroundColor Cyan
if ($WhatIf) { Write-Host '  (WhatIf mode - no changes will be made)' -ForegroundColor Yellow }
Write-Host ''

$servers = Get-MappedDriveServers

if ($servers.Count -eq 0) {
    Write-Host 'No mapped drives found.' -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($servers.Count) mapped drive server(s):"
Write-Host ''

foreach ($entry in $servers.GetEnumerator()) {
    $server = $entry.Key
    $unc    = $entry.Value
    $isIP   = $server -match '^\d{1,3}(\.\d{1,3}){3}$'

    if ($isIP) {
        Add-IPToIntranet       -IP       $server -UncPath $unc
    } else {
        Add-HostnameToIntranet -Hostname $server -UncPath $unc
    }
}

if (-not $WhatIf) {
    Write-Host ''
    Write-Host 'Done.' -ForegroundColor Cyan
    Write-Host 'Changes take effect for new Explorer windows immediately.' -ForegroundColor DarkGray
    Write-Host 'If previews still fail, sign out and back in to flush the zone cache.' -ForegroundColor DarkGray
}
