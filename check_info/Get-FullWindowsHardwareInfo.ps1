<#
.SYNOPSIS
  Full Windows + hardware info script.

.DESCRIPTION
  Collects OS, CPU, RAM, GPU, disks, network, BIOS, motherboard info.
  Saves report automatically to every user's Desktop as SystemReport.txt.
#>

function Write-Section { param($title); Out ""; $line = '-' * ([Math]::Max(10, ($title.Length + 4))); Out $line; Out "  $title"; Out $line }
function Safe-Get { param($scriptBlock); try { & $scriptBlock } catch { Out "  <error retrieving data: $($_.Exception.Message)>" } }

$sb = New-Object System.Text.StringBuilder
function Out($text) { $null = $sb.AppendLine($text); Write-Output $text }

Out "Full Windows + Hardware Specification Report"
Out "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# --- OS ---
Write-Section "Operating System"
Safe-Get {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $ci = @{}
    $ci.ProductName = (Get-ComputerInfo -Property OsName -ErrorAction SilentlyContinue).OsName
    if (-not $ci.ProductName) { $ci.ProductName = $os.Caption }
    $ci.Version = $os.Version
    $ci.BuildNumber = $os.BuildNumber
    $ci.InstallDate = ($os.InstallDate -as [datetime]).ToLocalTime()
    $ci.LastBoot = ($os.LastBootUpTime -as [datetime]).ToLocalTime()
    $ci.OSArchitecture = $os.OSArchitecture
    $ci.ComputerName = $env:COMPUTERNAME
    $ci.Domain = $cs.Domain
    $ci.SerialNumber = (Get-CimInstance Win32_BIOS -ErrorAction SilentlyContinue).SerialNumber
    Out "Product: $($ci.ProductName)"
    Out "Version: $($ci.Version)    Build: $($ci.BuildNumber)    Architecture: $($ci.OSArchitecture)"
    Out "Install Date: $($ci.InstallDate)    Last Boot: $($ci.LastBoot)"
    Out "Computer Name: $($ci.ComputerName)    Domain: $($ci.Domain)"
    Out "System Serial: $($ci.SerialNumber)"
}

# --- System ---
Write-Section "System (Chassis / Mainboard / BIOS)"
Safe-Get {
    $bios = Get-CimInstance Win32_BIOS
    $base = Get-CimInstance Win32_BaseBoard
    $cs = Get-CimInstance Win32_ComputerSystem
    Out "Manufacturer: $($cs.Manufacturer)    Model: $($cs.Model)"
    Out "System Type: $($cs.SystemType)    Total Physical Memory: $([math]::Round($cs.TotalPhysicalMemory/1GB,2)) GB"
    Out "Baseboard Manufacturer: $($base.Manufacturer)    Product: $($base.Product)    Version: $($base.Version)"
    Out "BIOS Vendor: $($bios.Manufacturer)    BIOS Version: $($bios.SMBIOSBIOSVersion)"
    Out "BIOS Release Date: $($bios.ReleaseDate -as [datetime])    Serial: $($bios.SerialNumber)"
}

# --- CPU ---
Write-Section "Processors (CPU)"
Safe-Get {
    $cpus = Get-CimInstance Win32_Processor
    $i = 0
    foreach ($cpu in $cpus) {
        $i++
        Out "CPU #${i}: $($cpu.Name)    Manufacturer: $($cpu.Manufacturer)    Cores: $($cpu.NumberOfCores)    LogicalProc: $($cpu.NumberOfLogicalProcessors)    MaxClockMHz: $($cpu.MaxClockSpeed) MHz"
        Out "  Socket: $($cpu.SocketDesignation)    ID: $($cpu.DeviceID)    CurrentClock: $($cpu.CurrentClockSpeed) MHz"
    }
}

# --- Memory ---
Write-Section "Memory (RAM modules)"
Safe-Get {
    $memModules = Get-CimInstance Win32_PhysicalMemory | Sort-Object BankLabel
    $total = 0
    $idx = 0
    foreach ($m in $memModules) {
        $idx++
        $sizeGB = [math]::Round($m.Capacity/1GB,3)
        $total += $m.Capacity
        Out "Module ${idx}: Bank=$($m.BankLabel) DevLocator=$($m.DeviceLocator) Size=${sizeGB}GB Type=$($m.MemoryType) Speed=$($m.Speed)MHz Manufacturer=$($m.Manufacturer) PartNumber=$($m.PartNumber) Serial=$($m.SerialNumber)"
    }
    if ($memModules) { Out "Total Physical RAM: $([math]::Round($total/1GB,3)) GB" } else { Out "No physical memory module info available via WMI." }
}

# --- GPU ---
Write-Section "Graphics (GPU)"
Safe-Get {
    $gpus = Get-CimInstance Win32_VideoController
    $i = 0
    foreach ($g in $gpus) {
        $i++
        Out "GPU #${i}: $($g.Name)    AdapterRAM: $([math]::Round($g.AdapterRAM/1MB)) MB    DriverVersion: $($g.DriverVersion)    VideoProcessor: $($g.VideoProcessor)"
    }
}

# --- Disks ---
Write-Section "Storage (Physical Disks)"
Safe-Get {
    $drives = Get-CimInstance Win32_DiskDrive
    $i=0
    foreach ($dd in $drives) {
        $i++
        Out "Disk #${i}: Model=$($dd.Model) Interface=$($dd.InterfaceType) SizeGB=$([math]::Round($dd.Size/1GB,2)) Serial=$($dd.SerialNumber) MediaType=$($dd.MediaType)"
    }
    Out ""
    Out "Partitions & Volumes:"
    $vols = Get-Volume -ErrorAction SilentlyContinue
    if ($vols) {
        foreach ($v in $vols) {
            Out "  DriveLetter=$($v.DriveLetter)  Label='$($v.FileSystemLabel)'  FS=$($v.FileSystem)  Size=$([math]::Round($v.Size/1GB,2))GB  Free=$([math]::Round($v.SizeRemaining/1GB,2))GB  Health=$($v.HealthStatus)"
        }
    }
}

# --- Network ---
Write-Section "Network Adapters"
Safe-Get {
    $nics = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Sort-Object Name
    foreach ($nic in $nics) {
        $ifIndex = $nic.ifIndex
        $ipcfg = Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.PrefixOrigin -ne "WellKnown" }
        $ips = if ($ipcfg) { ($ipcfg | ForEach-Object { "$($_.IPAddress)/$($_.PrefixLength)" }) -join ", " } else { "<no ipv4>" }
        Out "NIC: $($nic.Name)    Status=$($nic.Status)    LinkSpeed=$($nic.LinkSpeed)    MAC=$($nic.MacAddress)    IP=$ips"
    }
}

# --- Auto-save to all Desktops ---
Write-Section "Saving Report"
$desktops = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName "Desktop" } | Where-Object { Test-Path $_ }
foreach ($d in $desktops) {
    $outFile = Join-Path $d "SystemReport.txt"
    try {
        $sb.ToString() | Out-File -FilePath $outFile -Encoding UTF8 -Force
        Out "Report saved to: $outFile"
    } catch {
        Out "Failed to save to $outFile : $($_.Exception.Message)"
    }
}

Out ""
Out "End of report."
