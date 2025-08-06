# Ensure the registry path exists
$path = "HKLM:\SOFTWARE\Policies\Microsoft\PassportForWork"
if (!(Test-Path $path)) {
    New-Item -Path $path -Force | Out-Null
}

# Enable Windows Hello for Business
Set-ItemProperty -Path $path -Name "Enabled" -Type DWord -Value 1

# Disable provisioning after sign-in
Set-ItemProperty -Path $path -Name "DisablePostLogonProvisioning" -Type DWord -Value 1

Write-Host "Windows Hello for Business policy applied."
