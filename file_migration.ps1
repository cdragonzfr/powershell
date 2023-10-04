param(
    [Parameter(Mandatory=$true)]
    [string]$DriveLetter,
    [Parameter(Mandatory=$true)]
    [string]$NetworkPath,
    [Parameter(Mandatory=$true)]
    [string]$DirectoriesCsv,
    [Parameter(Mandatory=$true)]
    [string]$FilesCsv,
    [Parameter(Mandatory=$true)]
    [string]$OwnerUser,
    [Parameter(Mandatory=$true)]
    [string]$LogFile
)

# Map Network Drive
net use $DriveLetter $NetworkPath

# Function to replace drive letter with mapped drive
function ConvertToMappedPath($path) {
    return $path -replace "^[A-Z]:", $DriveLetter
}

# Create Directories and set ACL
Import-Csv $DirectoriesCsv | ForEach-Object {
    $directory = ConvertToMappedPath($_.DirectoryPath)

    # Create directory
    New-Item -Path $directory -ItemType Directory

    # Set ACL
    $acl = Get-Acl -Path $directory
    $everyone = New-Object system.security.principal.NTAccount("Everyone")
    $administrators = New-Object system.security.principal.NTAccount("Administrators")
    $owner = New-Object system.security.principal.NTAccount($OwnerUser)

    $everyonePermission = New-Object system.security.accesscontrol.filesystemaccessrule($everyone, "FullControl", "Allow")
    $adminPermission = New-Object system.security.accesscontrol.filesystemaccessrule($administrators, "FullControl", "Allow")

    $acl.SetAccessRuleProtection($true, $false)
    $acl.SetOwner($owner)
    $acl.AddAccessRule($everyonePermission)
    $acl.AddAccessRule($adminPermission)
    Set-Acl -Path $directory -AclObject $acl

    Add-Content -Path $LogFile -Value "Directory $directory created and permissions set."
}

# Move Files and set ACL
Import-Csv $FilesCsv | ForEach-Object {
    $source = $_.SourcePath
    $destination = ConvertToMappedPath($_.DestinationPath)

    # Move file
    Move-Item -Path $source -Destination $destination

    # Set ACL
    $acl = Get-Acl -Path $destination
    $everyone = New-Object system.security.principal.NTAccount("Everyone")
    $administrators = New-Object system.security.principal.NTAccount("Administrators")

    $everyonePermission = New-Object system.security.accesscontrol.filesystemaccessrule($everyone, "FullControl", "Allow")
    $adminPermission = New-Object system.security.accesscontrol.filesystemaccessrule($administrators, "FullControl", "Allow")

    $acl.SetAccessRuleProtection($true, $false)
    $acl.AddAccessRule($everyonePermission)
    $acl.AddAccessRule($adminPermission)
    Set-Acl -Path $destination -AclObject $acl

    Add-Content -Path $LogFile -Value "File $source moved to $destination and permissions set."
}
