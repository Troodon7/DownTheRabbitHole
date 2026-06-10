#Requires -Version 3.0
# Adds mapped drive UNC servers to the Windows Local Intranet trusted zone.
# Fixes PDF and file preview failures in Windows Explorer on network shares.
# No admin rights required - changes are per-user (HKCU).
#
# Usage:
#   .\PreviewPanelFix.ps1          - apply changes
#   .\PreviewPanelFix.ps1 -WhatIf  - dry run, no changes written

param(
    [switch]$WhatIf
)

$DomainsPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'
$DomainsReg  = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains'
$RangesReg   = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges'
$RangesPSH   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges'
$IntranetZone = 1

function Get-MappedDriveServers {
    $servers  = @{}
    $uncPaths = @()

    # Source 1: HKCU:\Network registry key
    try {
        $regDrives = Get-ChildItem 'HKCU:\Network' -ErrorAction SilentlyContinue
        foreach ($drive in $regDrives) {
            $remote = (Get-ItemProperty -Path $drive.PSPath -ErrorAction SilentlyContinue).RemotePath
            if ($remote) { $uncPaths += $remote }
        }
    } catch {}

    # Source 2: Get-PSDrive (FileSystem provider, network roots)
    try {
        $psDrives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue |
                    Where-Object { $_.DisplayRoot -like '\\*' }
        foreach ($d in $psDrives) {
            if ($d.DisplayRoot -notin $uncPaths) { $uncPaths += $d.DisplayRoot }
        }
    } catch {}

    # Source 3: Get-SmbMapping
    try {
        $smb = Get-SmbMapping -ErrorAction SilentlyContinue
        foreach ($m in $smb) {
            if ($m.RemotePath -notin $uncPaths) { $uncPaths += $m.RemotePath }
        }
    } catch {}

    # Source 4: net use
    try {
        $netLines = & net use 2>&1
        foreach ($line in $netLines) {
            if ($line -match '(\\\\[^\s]+)') {
                if ($Matches[1] -notin $uncPaths) { $uncPaths += $Matches[1] }
            }
        }
    } catch {}

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

# IP addresses: ZoneMap\Ranges\RangeN with * = DWORD 1 and :Range = REG_SZ (IP)
# This matches exactly what Internet Options writes when adding an IP manually.
function Add-IPToIntranet {
    param([string]$IP, [string]$UncPath)

    $alreadySet = $false
    $existingKey = $null

    $queryOut = & reg query $RangesReg 2>&1
    foreach ($line in $queryOut) {
        if ($line -match '\\(Range\d+)\s*$') {
            $fullKey  = "$RangesReg\$($Matches[1])"
            $rangeOut = & reg query $fullKey /v ':Range' 2>&1
            if ($rangeOut -match [regex]::Escape($IP)) {
                $alreadySet  = $true
                $existingKey = $fullKey
                break
            }
        }
    }

    if ($WhatIf) {
        if ($alreadySet) {
            Write-Host "  OK     $IP  ($UncPath) - already set" -ForegroundColor DarkGray
        } else {
            Write-Host "  WOULD ADD  $IP  ($UncPath)" -ForegroundColor Cyan
        }
        return
    }

    if ($alreadySet) {
        & reg add $existingKey /v '*'      /t REG_DWORD /d 1   /f 2>&1 | Out-Null
        & reg add $existingKey /v ':Range' /t REG_SZ    /d $IP /f 2>&1 | Out-Null
        Write-Host "  OK     $IP  ($UncPath) - verified" -ForegroundColor DarkGray
        return
    }

    $n = 1
    while (Test-Path "$RangesPSH\Range$n") { $n++ }
    $newKey = "$RangesReg\Range$n"

    & reg add $newKey /f                                        2>&1 | Out-Null
    & reg add $newKey /v '*'      /t REG_DWORD /d 1   /f       2>&1 | Out-Null
    & reg add $newKey /v ':Range' /t REG_SZ    /d $IP /f       2>&1 | Out-Null

    Write-Host "  ADDED  $IP  ($UncPath) -> Range$n" -ForegroundColor Green
}

# Hostnames: ZoneMap\Domains\hostname with * = DWORD 1
function Add-HostnameToIntranet {
    param([string]$Hostname, [string]$UncPath)

    $existing   = & reg query "$DomainsReg\$Hostname" /v '*' 2>&1
    $alreadySet = $existing -match '\*\s+REG_DWORD\s+0x1'

    if ($WhatIf) {
        if ($alreadySet) {
            Write-Host "  OK     $Hostname  ($UncPath) - already set" -ForegroundColor DarkGray
        } else {
            Write-Host "  WOULD ADD  $Hostname  ($UncPath)" -ForegroundColor Cyan
        }
        return
    }

    & reg add "$DomainsReg\$Hostname" /v '*' /t REG_DWORD /d 1 /f 2>&1 | Out-Null

    if ($alreadySet) {
        Write-Host "  OK     $Hostname  ($UncPath) - verified" -ForegroundColor DarkGray
    } else {
        Write-Host "  ADDED  $Hostname  ($UncPath)" -ForegroundColor Green
    }
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

Write-Host ''
Write-Host 'Checking PDF preview handler...' -ForegroundColor Cyan

$previewHandlerGuid = '{8895b1c6-b41f-4c1c-a562-0d564250836f}'
$handlerPaths = @(
    "HKCU:\SOFTWARE\Classes\.pdf\ShellEx\$previewHandlerGuid",
    "HKCR:\.pdf\ShellEx\$previewHandlerGuid",
    "HKLM:\SOFTWARE\Classes\.pdf\ShellEx\$previewHandlerGuid"
)

$handlerFound = $false
foreach ($path in $handlerPaths) {
    try {
        $val = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
        $clsid = $val.'(default)'
        if ($clsid) {
            $name = $null
            try { $name = (Get-ItemProperty "HKCR:\CLSID\$clsid"           -ErrorAction SilentlyContinue).'(default)' } catch {}
            try { if (-not $name) { $name = (Get-ItemProperty "HKLM:\SOFTWARE\Classes\CLSID\$clsid" -ErrorAction SilentlyContinue).'(default)' } } catch {}
            $label = if ($name) { $name } else { $clsid }
            Write-Host "  OK     PDF preview handler registered: $label" -ForegroundColor Green
            $handlerFound = $true
            break
        }
    } catch {}
}

if (-not $handlerFound) {
    Write-Host '  WARNING  No PDF preview handler found.' -ForegroundColor Yellow
    Write-Host '           Microsoft Edge does not register an Explorer preview handler' -ForegroundColor Yellow
    Write-Host '           even when set as the default PDF app - this is a known limitation.' -ForegroundColor Yellow
    Write-Host '           Install one of the following (all free):' -ForegroundColor Yellow
    Write-Host '             - Adobe Acrobat Reader  https://get.adobe.com/reader/' -ForegroundColor Yellow
    Write-Host '               (after install: Preferences > General > Enable PDF Thumbnail previews)' -ForegroundColor Yellow
    Write-Host '             - Foxit PDF Reader       https://www.foxit.com/pdf-reader/' -ForegroundColor Yellow
    Write-Host '             - PDF-XChange Viewer     https://www.tracker-software.com/product/pdf-xchange-viewer' -ForegroundColor Yellow
}

if (-not $WhatIf) {
    Write-Host ''
    Write-Host 'Done.' -ForegroundColor Cyan
    Write-Host 'Changes take effect for new Explorer windows immediately.' -ForegroundColor DarkGray
    Write-Host 'If previews still fail, sign out and back in to flush the zone cache.' -ForegroundColor DarkGray
}
