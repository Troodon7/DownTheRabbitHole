# Active Directory & User Management

Scripts for Active Directory, local user accounts, group policy, and Windows credential management.

## Scripts

### on-prem-AD-usermembership.ps1
PowerShell script that exports all Active Directory users and their group memberships to a CSV file.

### Redacted-local-user-add+admin.ps1
PowerShell script that creates a local user account and adds it to the local Administrators group. Skips creation if the user already exists.

### Redacted-gpupdateforce.ps1
PowerShell script that remotely forces a Group Policy update on a list of computers using `Invoke-GPUpdate`. Logs results for each machine.

### cred-manager-all-matching-1-target-only.ps1
PowerShell script that searches Windows Credential Manager for all entries matching a single username and deletes them.

### cred-manager-all-matching-multiple-targets.ps1
PowerShell script that searches Windows Credential Manager for entries matching multiple username patterns (supports regex) and deletes them all.

### cred-manager-all-matching-oneline-multiple-targets.bat
One-liner batch/PowerShell version of the multiple-target credential cleanup script above.

### Clear-Network-Credentials.ps1
PowerShell script that disconnects all mapped network drives and removes all saved credentials from Windows Credential Manager.
