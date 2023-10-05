# Extract hostname from $NetworkPath
$hostname = if ($NetworkPath -match '\\\\([^\\]+)\\') { $matches[1] } else { "unknown" }

<#
.SYNOPSIS
A brief description of the script.

.DESCRIPTION
A detailed description of the script.

.PARAMETER DriveLetter
The drive letter to use for the network drive mapping. For example: "Z:"

.PARAMETER NetworkPath
The UNC path of the network share. For example: "\\server\share"

.PARAMETER DirectoriesCsv
Path to the CSV file that contains directory paths to create. 
CSV should have a column titled 'DirectoryPath'.

.PARAMETER FilesCsv
Path to the CSV file that lists source files and their respective destination paths. 
CSV should have columns titled 'SourcePath' and 'DestinationPath'.

.PARAMETER OwnerUser
The domain and username for the owner. For example: "DOMAIN\username"

.PARAMETER LogFile
The path where the log file should be written. The hostname will be included in the log file name.

.EXAMPLE
.\YourScriptName.ps1 -DriveLetter "Z:" -NetworkPath "\\server\share" -DirectoriesCsv "C:\path\to\Directories.csv" -FilesCsv "C:\path\to\Files.csv" -OwnerUser "DOMAIN\username"

.NOTES
Any additional notes you'd like to include.

.LINK
URL to further reading or documentation if needed.
#>
