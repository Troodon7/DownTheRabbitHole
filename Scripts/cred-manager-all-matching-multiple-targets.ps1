# Define the specific users to delete
$UsersToDelete = @('^theusername$', '^adomainorother\\theusername$')

# Get all credentials from cmdkey
$CredentialsList = cmdkey.exe /list

# Initialize an empty array to store the Target: fields to be deleted
$TargetsToDelete = @()

# Parse the credential list
$CredentialBlock = ""

foreach ($Line in $CredentialsList) {
    $CredentialBlock += $Line + [Environment]::NewLine

    if ([string]::IsNullOrWhiteSpace($Line)) {
        # Debugging: Print the entire credential block
        Write-Host "Credential Block:" -ForegroundColor Cyan
        Write-Output $CredentialBlock

        # Extract the User field
        if ($CredentialBlock -match "User:\s*(.+)") {
            $User = $matches[1].Trim()

            # Check if the User matches the allowed patterns
            foreach ($UserPattern in $UsersToDelete) {
                if ($User -match $UserPattern) {
                    Write-Host "Matched User: $User (Pattern: $UserPattern)" -ForegroundColor Green

                    # Extract the Target field
                    if ($CredentialBlock -match "Target:\s*(\S+)") {
                        $Target = $matches[1]
                        $TargetsToDelete += $Target
                        Write-Host "Found Target for deletion: $Target" -ForegroundColor Green
                    }
                }
            }
        }
        $CredentialBlock = ""
    }
}

# Debugging: Display the targets to be deleted
Write-Host "Targets to be deleted:" -ForegroundColor Yellow
Write-Output $TargetsToDelete

# Now delete the targets in the list
foreach ($Target in $TargetsToDelete) {
    cmdkey.exe /delete $Target | Out-Null
    Write-Host "Deleted credential for Target: $Target" -ForegroundColor Green
}

# Final message
if ($TargetsToDelete.Count -eq 0) {
    Write-Host "No matching credentials found for specified users." -ForegroundColor Red
} else {
    Write-Host "All matching credentials deleted." -ForegroundColor Green
}
