# Get the currently logged-in user (in AzureAD\user format)
$CurrentUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName

# Check if we have a valid username
if ($CurrentUser -and $CurrentUser -like "*\*") {
    try {
        Write-Host "Adding $CurrentUser to local Administrators group..."
        Add-LocalGroupMember -Group "Administrators" -Member $CurrentUser
        Write-Host "Success! $CurrentUser is now a local admin."
    } catch {
        Write-Error "Failed to add $CurrentUser to Administrators: $_"
    }
} else {
    Write-Warning "Unable to determine a valid logged-in user. Skipping."
}
