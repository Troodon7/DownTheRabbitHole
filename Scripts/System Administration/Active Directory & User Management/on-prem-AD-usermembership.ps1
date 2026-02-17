# Import AD Module (skip if already loaded)
Import-Module ActiveDirectory

# Get all users with group membership
$users = Get-ADUser -Filter * -Properties MemberOf | ForEach-Object {
    [PSCustomObject]@{
        Username   = $_.SamAccountName
        DisplayName = $_.Name
        Email      = $_.EmailAddress
        Groups     = ($_.MemberOf | ForEach-Object {
            (Get-ADGroup $_).Name
        }) -join ", "
    }
}

# Export the result to CSV
$users | Export-Csv -Path "AD_Users_with_Groups.csv" -NoTypeInformation
