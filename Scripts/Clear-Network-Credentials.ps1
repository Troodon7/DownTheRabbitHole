
# Disconnect all mapped network drives
net use * /delete /y

# Remove all saved credentials using cmdkey
$credTargets = cmdkey /list | Where-Object { $_ -like "Target:*" } | ForEach-Object {
    ($_ -split "Target:")[1].Trim()
}

foreach ($target in $credTargets) {
    Write-Host "Deleting credential for $target"
    cmdkey /delete:$target
}
