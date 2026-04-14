# =========================
# CONFIGURATION
# =========================
$SqlServer   = "localhost"
$Database    = "master"
$AuditPath   = "C:\AuditLogs\*.sqlaudit"

$OutputDir   = "C:\AuditJSON\"
$LogFile     = "C:\AuditJSON\audit_ingest.log"

$MaxEventsPerFile = 5000   # Rotate file after this many events

# Ensure output directory exists
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# =========================
# LOG FUNCTION
# =========================
function Write-Log {
    param ($msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $msg" | Out-File -Append $LogFile
}

Write-Log "===== Script started ====="

# =========================
# GET LAST CHECKPOINT
# =========================
$queryCheckpoint = @"
IF OBJECT_ID('dbo.SplunkAuditCheckpoint', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.SplunkAuditCheckpoint (
        id INT IDENTITY(1,1) PRIMARY KEY,
        last_event_time DATETIME2
    );

    INSERT INTO dbo.SplunkAuditCheckpoint (last_event_time)
    VALUES ('2000-01-01');
END

SELECT TOP 1 last_event_time
FROM dbo.SplunkAuditCheckpoint
ORDER BY id DESC;
"@

try {
    $lastTime = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $Database -Query $queryCheckpoint |
        Select-Object -ExpandProperty last_event_time
} catch {
    Write-Log "ERROR: Failed to get checkpoint $_"
    exit 1
}

Write-Log "Last checkpoint: $lastTime"

# =========================
# QUERY AUDIT DATA
# =========================
$queryAudit = @"
SELECT *
FROM sys.fn_get_audit_file('$AuditPath', DEFAULT, DEFAULT)
WHERE event_time > DATEADD(SECOND, -10, '$lastTime')
ORDER BY event_time ASC;
"@

try {
    $auditData = Invoke-Sqlcmd -ServerInstance $SqlServer -Database $Database -Query $queryAudit
} catch {
    Write-Log "ERROR: Failed to query audit data $_"
    exit 1
}

if (!$auditData -or $auditData.Count -eq 0) {
    Write-Log "No new audit events."
    exit 0
}

Write-Log "Events retrieved: $($auditData.Count)"

# =========================
# WRITE JSON FILES
# =========================
$eventCount = 0
$fileIndex = 1
$currentFile = "$OutputDir\audit_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$fileIndex.json"

$maxEventTime = $lastTime

foreach ($row in $auditData) {

    # Track max timestamp
    if ($row.event_time -gt $maxEventTime) {
        $maxEventTime = $row.event_time
    }

    # Build clean JSON object
    $eventObj = @{
        event_time     = $row.event_time
        action_id      = $row.action_id
        succeeded      = $row.succeeded
        session_id     = $row.session_id
        server_principal_name = $row.server_principal_name
        database_name  = $row.database_name
        object_name    = $row.object_name
        statement      = $row.statement
        client_ip      = $row.client_ip
        application_name = $row.application_name
    }

    # Convert to JSON (single line)
    $jsonLine = ($eventObj | ConvertTo-Json -Compress -Depth 5)

    try {
        Add-Content -Path $currentFile -Value $jsonLine
    } catch {
        Write-Log "ERROR: Failed writing JSON $_"
        continue
    }

    $eventCount++

    # Rotate file
    if ($eventCount -ge $MaxEventsPerFile) {
        $fileIndex++
        $eventCount = 0
        $currentFile = "$OutputDir\audit_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$fileIndex.json"
    }
}

Write-Log "Finished writing JSON files."

# =========================
# UPDATE CHECKPOINT
# =========================
$updateCheckpoint = @"
INSERT INTO dbo.SplunkAuditCheckpoint (last_event_time)
VALUES ('$maxEventTime');
"@

try {
    Invoke-Sqlcmd -ServerInstance $SqlServer -Database $Database -Query $updateCheckpoint
    Write-Log "Checkpoint updated to $maxEventTime"
} catch {
    Write-Log "ERROR: Failed updating checkpoint $_"
}

Write-Log "===== Script completed ====="
