# === CONFIGURATION ===
$Username = "a-local-username"
$PasswordPlain = "a-clear-text-password"  # <-- change this!
$Password = ConvertTo-SecureString $PasswordPlain -AsPlainText -Force

# === CHECK IF USER EXISTS ===
if (-Not (Get-LocalUser -Name $Username -ErrorAction SilentlyContinue)) {
    # === CREATE USER ===
    New-LocalUser -Name $Username -Password $Password -FullName "ASM Tech User" -Description "Local admin account for IT" -PasswordNeverExpires:$true -AccountNeverExpires:$true

    Write-Host "User '$Username' created successfully."
} else {
    Write-Host "User '$Username' already exists."
}

# === ADD USER TO LOCAL ADMIN GROUP ===
$Group = "Administrators"
Add-LocalGroupMember -Group $Group -Member $Username
Write-Host "User '$Username' added to local '$Group' group."
