#Requires -Version 3.0
<#
.SYNOPSIS
    Adds mapped drive UNC servers to the Windows Local Intranet trusted zone.

.DESCRIPTION
    Scans all mapped network drives, extracts the server/hostname from each UNC
    path, and writes the appropriate registry entries under Internet Settings
    ZoneMap so Windows treats those file paths as Local Intranet. This fixes
    PDF (and other file) preview failures in Windows Explorer for network shares.

    Hostnames go into ZoneMap\Domains\<hostname>  (file = DWORD 1)
    IP addresses go into ZoneMap\Ranges\RangeN    (:Range = DWORD 1, <ip> = IP)

    No admin rights required — changes are per-user (HKCU).

.PARAMETER WhatIf
    Show what would be added without writing any registry keys.

.EXAMPLE
    .\Add-MappedDrivesToIntranet.ps1
    .\Add-MappedDrivesToIntranet.ps1 -WhatIf
#>

param(
    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$DomainsPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'
$RangesPath  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges'
$IntranetZone = 1

# ---------------------------------------------------------------------------
# Collect mapped drives -> hashtable of server -> drive letter
# ---------------------------------------------------------------------------
function Get-MappedDriveServers {
    $servers = [ordered]@{}

    # Prefer Get-SmbMapping (Win8+); fall back to parsing net use output
    $uncPaths = @()
    try {
        $uncPaths = (Get-SmbMapping -ErrorAction Stop).RemotePath
    } catch {
        $netLines = & net use 2>$null
        foreach ($line in $netLines) {
            if ($line -match '(\\\\[^\s]+)') {
                $uncPaths += $Matches[1]
            }
        }
    }

    foreach ($unc in $uncPaths) {
        if ($unc -match '^\\\\([^\\]+)\\?(.*)') {
            $server = $Matches[1]
            if (-not $servers.Contains($server)) {
                $servers[$server] = $unc
            }
        }
    }

    return $servers
}

# ---------------------------------------------------------------------------
# Add a hostname to ZoneMap\Domains
# ---------------------------------------------------------------------------
function Add-HostnameToIntranet {
    param([string]$Hostname, [string]$UncPath)

    $keyPath = Join-Path $DomainsPath $Hostname

    $existing = Get-ItemProperty -Path $keyPath -Name 'file' -ErrorAction SilentlyContinue
    if ($existing -and $existing.file -eq $IntranetZone) {
        Write-Host "  SKIP  $Hostname  ($UncPath) — already in Local Intranet zone" -ForegroundColor DarkGray
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

# ---------------------------------------------------------------------------
# Add an IP address to ZoneMap\Ranges
# ---------------------------------------------------------------------------
function Add-IPToIntranet {
    param([string]$IP, [string]$UncPath)

    # Check if already present in any existing Range entry
    $existing = Get-ChildItem -Path $RangesPath -ErrorAction SilentlyContinue
    foreach ($range in $existing) {
        $props = Get-ItemProperty -Path $range.PSPath -ErrorAction SilentlyContinue
        if ($props -and $props.'<ip>' -eq $IP -and $props.':Range' -eq $IntranetZone) {
            Write-Host "  SKIP  $IP  ($UncPath) — already in Local Intranet zone" -ForegroundColor DarkGray
            return
        }
    }

    if ($WhatIf) {
        Write-Host "  WOULD ADD  $IP  ($UncPath)" -ForegroundColor Cyan
        return
    }

    # Find next available RangeN slot
    $n = 1
    while (Test-Path (Join-Path $RangesPath "Range$n")) { $n++ }
    $newPath = Join-Path $RangesPath "Range$n"

    New-Item -Path $newPath -Force | Out-Null
    Set-ItemProperty -Path $newPath -Name '<ip>'   -Value $IP            -Type String
    Set-ItemProperty -Path $newPath -Name ':Range' -Value $IntranetZone  -Type DWord

    Write-Host "  ADDED  $IP  ($UncPath) -> Range$n" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$banner = 'Mapped Drive -> Local Intranet Zone Fixer'
Write-Host "`n$banner" -ForegroundColor Cyan
Write-Host ('-' * $banner.Length) -ForegroundColor Cyan
if ($WhatIf) { Write-Host '  (WhatIf mode — no changes will be made)' -ForegroundColor Yellow }
Write-Host ''

$servers = Get-MappedDriveServers

if ($servers.Count -eq 0) {
    Write-Host 'No mapped drives found.' -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($servers.Count) mapped drive server(s):`n"

foreach ($entry in $servers.GetEnumerator()) {
    $server = $entry.Key
    $unc    = $entry.Value
    $isIP   = $server -match '^\d{1,3}(\.\d{1,3}){3}$'

    if ($isIP) {
        Add-IPToIntranet   -IP       $server -UncPath $unc
    } else {
        Add-HostnameToIntranet -Hostname $server -UncPath $unc
    }
}

if (-not $WhatIf) {
    Write-Host ''
    Write-Host 'Done.' -ForegroundColor Cyan
    Write-Host 'Changes take effect immediately for new Explorer windows.' -ForegroundColor DarkGray
    Write-Host 'If previews still fail, sign out and back in to flush the zone cache.' -ForegroundColor DarkGray
}
