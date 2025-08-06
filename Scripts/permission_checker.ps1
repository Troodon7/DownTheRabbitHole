# -------------------------
# FOLDER PERMISSION CHECKER
# -------------------------

$TargetPath = "C:\program files"  # <-- Set your folder path here

# Get all files and folders recursively
$Items = Get-ChildItem -Path $TargetPath -Recurse -Force

# Include the root folder itself
$Items = @((Get-Item -Path $TargetPath -Force)) + $Items

foreach ($Item in $Items) {
    Write-Host "`n--- Permissions for: $($Item.FullName) ---" -ForegroundColor Cyan
    try {
        $acl = Get-Acl -Path $Item.FullName
        foreach ($access in $acl.Access) {
            Write-Host ("{0,-25} {1,-20} {2,-15} {3}" -f `
                $access.IdentityReference,
                $access.FileSystemRights,
                $access.AccessControlType,
                $access.IsInherited)
        }
    } catch {
        Write-Warning "Failed to get ACL for $($Item.FullName): $_"
    }
}
