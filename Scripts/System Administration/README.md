# System Administration

Scripts for system management, reboots, configuration, and general IT administration.

## Scripts

### Reset-pc.ps1
PowerShell script that runs `systemreset -cleanpc` to factory reset the PC.

### Redacted-RebootAllPCs.ps1
PowerShell script that remotely reboots a list of computers using `Restart-Computer`. Logs success/failure for each machine.

### hostnamechange
Bash script that opens `/etc/hostname` and `/etc/hosts` in nano for editing, then reboots the system after a 2-minute grace period.

### fullscreen
Bash script that waits 60 seconds then launches a gnome-terminal in fullscreen mode running a specified script. Designed for kiosk setups.

### system_information.py
Python script that collects comprehensive system info (OS, CPU, memory, disk, network, GPU) using `psutil` and `GPUtil`, then exports it all to an Excel spreadsheet.

### requirements-for-system-information.txt
Pip requirements file for `system_information.py` (psutil, platformdirs, openpyxl, gputil, tabulate).

### Allow Execution.ps1
PowerShell one-liner that opens an elevated prompt and sets the execution policy to `RemoteSigned`.

### RunAsAdminInScript.ps1
PowerShell snippet that re-launches the current script as Administrator if not already elevated. Paste at the top of any script.

### RunAsAdminIn&PolicyUnrestricted.ps1
Same as above but also sets execution policy to `Unrestricted` after elevating.

### redacted-add-printers.ps1
PowerShell script that adds network printers by IP address. Creates printer ports and adds printers using pre-installed drivers.

### Get-sql-Product-Key.ps1
PowerShell function that retrieves the product key from a SQL Server 2012 installation by decoding the binary registry value.

## Subfolder

### [Active Directory & User Management](Active%20Directory%20%26%20User%20Management/)
Scripts for Active Directory, local user management, group policy, and credential management.
