@echo off
echo Run with -Force to rewrite entries even if already set.
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PreviewPanelFix.ps1" %*
pause
