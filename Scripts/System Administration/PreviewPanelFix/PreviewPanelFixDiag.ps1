# Diagnostic script - run this and paste the output
# so we can see exactly what the fix script is seeing

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host '=== Current User ===' -ForegroundColor Cyan
Write-Host ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
Write-Host "Running elevated: $isAdmin"
Write-Host ''

Write-Host '=== HKCU:\Network ===' -ForegroundColor Cyan
$net = Get-ChildItem 'HKCU:\Network' -ErrorAction SilentlyContinue
if ($net) {
    foreach ($d in $net) {
        $r = (Get-ItemProperty $d.PSPath -ErrorAction SilentlyContinue).RemotePath
        Write-Host "  $($d.PSChildName) -> $r"
    }
} else {
    Write-Host '  (empty or not found)'
}
Write-Host ''

Write-Host '=== Get-PSDrive (network only) ===' -ForegroundColor Cyan
Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like '\\*' } | Format-Table Name, DisplayRoot -AutoSize
Write-Host ''

Write-Host '=== Get-SmbMapping ===' -ForegroundColor Cyan
try {
    Get-SmbMapping -ErrorAction Stop | Format-Table LocalPath, RemotePath -AutoSize
} catch {
    Write-Host "  Error: $_"
}
Write-Host ''

Write-Host '=== net use ===' -ForegroundColor Cyan
& net use 2>&1
Write-Host ''

Write-Host '=== MountPoints2 ===' -ForegroundColor Cyan
$mp2 = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2'
Get-ChildItem $mp2 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty PSChildName | Where-Object { $_ -like '#*' }
Write-Host ''

# --- ZoneMap locations ---
$zonePaths = @(
    @{ Label = 'HKCU ZoneMap\Domains (user)';          Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains' },
    @{ Label = 'HKCU ZoneMap\Ranges (user)';           Path = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges' },
    @{ Label = 'HKLM ZoneMap\Domains (machine)';       Path = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains' },
    @{ Label = 'HKLM ZoneMap\Ranges (machine)';        Path = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges' },
    @{ Label = 'HKCU Policy ZoneMap\Domains (policy)'; Path = 'HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains' },
    @{ Label = 'HKCU Policy ZoneMap\Ranges (policy)';  Path = 'HKCU\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges' },
    @{ Label = 'HKLM Policy ZoneMap\Domains (policy)'; Path = 'HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains' },
    @{ Label = 'HKLM Policy ZoneMap\Ranges (policy)';  Path = 'HKLM\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Ranges' }
)

Write-Host '=== ZoneMap Locations ===' -ForegroundColor Cyan
foreach ($z in $zonePaths) {
    Write-Host "  $($z.Label):" -ForegroundColor Yellow
    $out = & reg query $z.Path 2>&1
    if ($out -match 'ERROR') {
        Write-Host '    (not found)' -ForegroundColor DarkGray
    } else {
        $out | Where-Object { $_ -match '\S' } | ForEach-Object { Write-Host "    $_" }
    }
}
