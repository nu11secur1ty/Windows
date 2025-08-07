# logarithm-nu11secur1ty.ps1

# Variables
$htmlPath = "$PSScriptRoot\LoginReport.html"
$currentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Start HTML
$html = @"
<html>
<head>
    <title>Login Report</title>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px; }
        h2 { color: #333; }
        .section { margin-bottom: 30px; }
        .current { color: red; font-weight: bold; }
        .history { color: gray; }
        .footer { font-size: 12px; color: #666; margin-top: 40px; }
    </style>
</head>
<body>
    <h1>Login Report</h1>
    <div class="footer">Generated: $currentDate</div>
"@

# ==== CURRENT USERS ====
$html += "<div class='section'><h2>Currently Logged-In Users</h2><ul>"

$loggedInUsers = quser 2>$null

if ($loggedInUsers) {
    $currentUsers = $loggedInUsers | Select-Object -Skip 1 | ForEach-Object {
        ($_ -replace '\s{2,}', ',') -split ',' | Select-Object -First 1
    } | Sort-Object -Unique

    foreach ($user in $currentUsers) {
        $html += "<li class='current'>$user</li>"
    }

    $html += "</ul><p><strong>Total:</strong> $($currentUsers.Count)</p>"
} else {
    $html += "<li class='current'>Could not retrieve logged-in users (admin required?)</li></ul>"
}

$html += "</div>"

# ==== HISTORICAL USERS ====
$html += "<div class='section'><h2>Historical Logins (Last 7 Days)</h2><ul>"

try {
    $startTime = (Get-Date).AddDays(-7)
    $logins = Get-WinEvent -FilterHashtable @{
        LogName = 'Security';
        Id = 4624;
        StartTime = $startTime
    } -ErrorAction Stop

    $historicalUsers = $logins | ForEach-Object {
        $xml = [xml]$_.ToXml()
        $account = $xml.Event.EventData.Data | Where-Object { $_.Name -eq 'TargetUserName' } | Select-Object -ExpandProperty '#text'
        $domain  = $xml.Event.EventData.Data | Where-Object { $_.Name -eq 'TargetDomainName' } | Select-Object -ExpandProperty '#text'

        if ($account -and $account -notmatch '^(ANONYMOUS LOGON|DWM-|UMFD-|LOCAL SERVICE|NETWORK SERVICE|SYSTEM|\$)') {
            "$domain\$account"
        }
    } | Sort-Object -Unique

    foreach ($user in $historicalUsers) {
        $html += "<li class='history'>$user</li>"
    }

    $html += "</ul><p><strong>Total:</strong> $($historicalUsers.Count)</p>"
}
catch {
    $html += "<li class='history'>Failed to retrieve event logs. Admin access may be required.</li></ul>"
}

# Close HTML
$html += "</div></body></html>"

# Save file
$html | Out-File -FilePath $htmlPath -Encoding UTF8

# Open in browser
Start-Process $htmlPath
