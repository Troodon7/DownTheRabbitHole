$UserToDelete = 'theusername'

# Get all credentials from cmdkey
$CredentialsList = cmdkey.exe /list

# Debugging: Display the raw output
Write-Host "Raw cmdkey output:" -ForegroundColor Yellow
Write-Output $CredentialsList

# Initialize an empty array to store the Target: fields to be deleted
$TargetsToDelete = @()

# Parse the credential list
$CredentialBlock = ""

foreach ($Line in $CredentialsList) {
    # Add line to the credential block
    $CredentialBlock += $Line + [Environment]::NewLine

    # If we encounter a blank line, process the current block
    if ([string]::IsNullOrWhiteSpace($Line)) {
        # Debugging: Display the current credential block
        Write-Host "Processing Credential Block:" -ForegroundColor Cyan
        Write-Output $CredentialBlock

        # Check if the User: field matches the specified username
        if ($CredentialBlock -match "User:\s*$($UserToDelete)") {
            # Extract the Target: field from this block
            if ($CredentialBlock -match "Target:\s*(\S+)") {
                $Target = $matches[1]
                # Add the Target to the deletion list
                $TargetsToDelete += $Target

                # Debugging: Show the matched target
                Write-Host "Found Target for deletion: $Target" -ForegroundColor Green
            }
        }
        # Reset the credential block for the next entry
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
    Write-Host "No matching credentials found for User: $UserToDelete" -ForegroundColor Red
} else {
    Write-Host "All matching credentials deleted." -ForegroundColor Green
}
