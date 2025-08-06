# Folder to create test files in
$targetFolder = "C:\Test delete\Delete inside"

# Number of files to create
$fileCount = 20

# Max age range in days (e.g., files will be between 0 and 90 days old)
$maxAgeDays = 90

# Ensure the folder exists
if (-not (Test-Path $targetFolder)) {
    New-Item -Path $targetFolder -ItemType Directory -Force | Out-Null
}

# Create random-aged files
for ($i = 1; $i -le $fileCount; $i++) {
    $fileName = "testfile_$i.txt"
    $filePath = Join-Path $targetFolder $fileName

    # Create the file
    New-Item -Path $filePath -ItemType File -Force | Out-Null

    # Generate a random age between 0 and $maxAgeDays
    $randomAge = Get-Random -Minimum 0 -Maximum $maxAgeDays
    $randomDate = (Get-Date).AddDays(-$randomAge)

    # Set timestamps
    $file = Get-Item $filePath
    $file.CreationTime = $randomDate
    $file.LastWriteTime = $randomDate
    $file.LastAccessTime = $randomDate

    Write-Host "Created $fileName with timestamp: $randomDate"
}
