# Define the path to the master list file
$masterListPath = "C:\path\to\masterlist.csv"

# Define the path for the output CSV file
$outputCsvPath = "C:\Temp\output.csv"

# Get the current system's hostname
$currentHostname = [System.Net.Dns]::GetHostName()

# Read the master list file and filter the records
$filteredRecords = Import-Csv $masterListPath | Where-Object { $_.Hostname -eq $currentHostname }

# Initialize an array to hold the output data
$outputData = @()

# Iterate through each filtered record
foreach ($record in $filteredRecords) {
    $filePath = $record.DirectoryPath
    $presence = 0

    # Check if the directory path and file exist
    if (Test-Path $filePath) {
        $presence = 1
    }

    # Create an object with the required properties
    $outputObj = [PSCustomObject]@{
        Hostname = $currentHostname
        FilePath = $filePath
        Presence = $presence
    }

    # Add the object to the output data array
    $outputData += $outputObj
}

# Export the output data to a CSV file
$outputData | Export-Csv -Path $outputCsvPath -NoTypeInformation

# Optional: Display a message when done
Write-Host "Output written to $outputCsvPath"
