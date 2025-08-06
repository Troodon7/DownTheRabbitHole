@echo off

set /p confirm="This script will permanently delete specific user data folders within your profile directory. Are you sure you want to continue? (Y/N): "
if /i "%confirm%" neq "Y" (
  if /i "%confirm%" neq "y" (
    if /i "%confirm%" neq "yes" (
      if /i "%confirm%" neq "Yes" (
        if /i "%confirm%" neq "yea" (
          if /i "%confirm%" neq "Yeah" (
            if /i "%confirm%" neq "Yea" (
              if /i "%confirm%" neq "yeah" (
                goto :eof
              )
            )
          )
        )
      )
    )
  )
)

set "target_directory=%userprofile%"

rem Specify the folders to be deleted within the user profile directory
rd /s /q "%target_directory%\Documents" 2>nul
rd /s /q "%target_directory%\Pictures" 2>nul
rd /s /q "%target_directory%\Videos" 2>nul

(goto) 2>nul & del "%~f0"
