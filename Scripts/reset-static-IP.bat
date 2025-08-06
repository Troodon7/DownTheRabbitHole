@echo off
timeout /t 10

REM Set interface to DHCP
netsh interface ip set address "Ethernet0" dhcp
netsh interface ip set dns "Ethernet0" dhcp

echo Static IP cleared and DHCP enabled.
