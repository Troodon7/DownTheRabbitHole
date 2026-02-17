# Networking

Scripts for network operations, Wake-on-LAN, monitoring, and Wi-Fi management.

## Scripts

### Send-WakeOnLan.ps1
PowerShell function that sends a Wake-on-LAN magic packet to a specified MAC address. Takes MAC address, broadcast address, and port as parameters.

### Redacted-WakeMultiple.sh
Bash script that opens multiple terminal windows to run Wake-on-LAN scripts in parallel for waking multiple machines at once.

### Redacted-wakeup_script.sh
Bash script that continuously pings a target device and sends Wake-on-LAN packets if it's offline. Loops until the device comes online.

### Redacted-Monitor-NIC-Resets.ps1
PowerShell script that monitors NIC disconnect/reset events in the Windows System log. When a NIC event is detected, it exports the system log and NIC statistics to the desktop.

### scannetworkv2.py
Python script using `nmap` to scan the local /24 subnet and write results (hosts, states, open ports) to a text file.

### reset-static-IP.bat
Batch script that resets the "Ethernet0" interface from a static IP back to DHCP (both address and DNS).

### Windows-Wifi-Passwords.ps1
PowerShell script that extracts saved Wi-Fi profile names and their stored passwords using `netsh`.
