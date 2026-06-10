@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PreviewPanelFix.ps1" %*
pause
