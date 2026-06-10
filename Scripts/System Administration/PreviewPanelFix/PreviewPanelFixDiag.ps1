# Diagnostic script - run this and paste the output
# so we can see exactly what the fix script is seeing

Write-Host '=== Current User ===' -ForegroundColor Cyan
[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
