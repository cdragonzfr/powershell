# Define the path to the master list file
$masterListPath = "C:\path\to\masterlist.csv"

# Get the current system's hostname
$currentHostname = [System.Net.Dns]::GetHostName()

# Read the master list file and filter the records
$filteredRecords = Import-Csv $masterListPath | Where-Object { $_.Hostname -eq $currentHostname }

# Iterate through each filtered record
foreach ($record in $filteredRecords) {
    $filePath = $record.DirectoryPath

    # Check if the directory path and file exist
    if (Test-Path $filePath) {
        Write-Host "File exists: $filePath"
    } else {
        Write-Host "File does not exist: $filePath"
    }
}
