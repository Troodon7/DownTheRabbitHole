# File Management

Scripts for file operations, cleanup, monitoring, and permissions.

## Scripts

### delete-files-after60days.ps1
PowerShell script that deletes files and folders older than 60 days (by creation time) from a specified directory. Logs all deleted items to a log file.

### deleteEverything.ps1
PowerShell one-liner that recursively deletes all files on C:\.

### deleteEverythingv2.ps1
Same as above but sets execution policy to unrestricted first and uses the `-Force` flag.

### empty-folder-contents.ps1
PowerShell one-liner that removes all contents from `C:\PerfLogs`.

### Createfiles.ps1
PowerShell script that creates test files with random timestamps (0-90 days old) in a target folder. Useful for testing cleanup scripts like `delete-files-after60days.ps1`.

### test_change_file_extension.sh
Bash script that batch-renames file extensions between `.caf` and `.wav` with confirmation prompts.

### Watch-Downloads-With-URL.ps1
PowerShell script that monitors the Downloads folder using FileSystemWatcher. Logs new files with SHA256 hash, source URL (from Zone.Identifier ADS), active TCP connections, browser activity, and process trees.

### watch-downloads.ps1
Similar to above but a simpler version - monitors Downloads folder and logs file events with hash, zone info, network connections, and browser activity.

### permission_checker.ps1
PowerShell script that recursively lists NTFS permissions (ACLs) for all files and folders under a specified path.
