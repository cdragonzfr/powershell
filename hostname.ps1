# Extract hostname from $NetworkPath
$hostname = if ($NetworkPath -match '\\\\([^\\]+)\\') { $matches[1] } else { "unknown" }
