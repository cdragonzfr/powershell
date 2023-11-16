# Define the path for the output CSV file
$outputCsvPath = "C:\Temp\output.csv"

# Get the current system's hostname
$currentHostname = [System.Net.Dns]::GetHostName()

# Check if the output CSV file exists
if (-not (Test-Path $outputCsvPath)) {
    # Output CSV does not exist, write out the hostname and message
    Write-Host "$currentHostname|File does not exist"
    exit
}

# Read the output CSV file
$outputData = Import-Csv -Path $outputCsvPath

# Iterate over the data and write it out in Tanium sensor friendly format
foreach ($record in $outputData) {
    $formattedOutput = "$($record.Hostname)|$($record.FilePath)|$($record.Presence)"
    Write-Host $formattedOutput
}
