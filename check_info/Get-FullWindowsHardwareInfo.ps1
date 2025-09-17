<#
.SYNOPSIS
  Print a detailed Windows and hardware specification report.

.DESCRIPTION
  Collects OS details, CPU, memory, GPU, disks, volumes, network adapters, BIOS, motherboard, and other system info.
  Save as Get-FullWindowsHardwareInfo.ps1 and run in an elevated PowerShell session.

.EXAMPLE
  .\Get-FullWindowsHardwareInfo.ps1
  .\Get-FullWindowsHardwareInfo.ps1 -OutputFile C:\temp\SystemReport.txt
#>

param(
    [string]$OutputFile = $null
)

function Write-Section {
    param($title)
    $line = '-' * ([Math]::Max(10, ($title.Length + 4)))
    Write-Output ""
    Write-Output $line
    Write-Output "  $title"
    Write-Output $line
}

function Safe-Get {
    param($scriptBlock)
    try {
        & $scriptBlock
    } catch {
        Write-Output "  <error retrieving data: $($_.Exception.Message)>"
    }
}

# Capture output (for optional file)
$sb = New-Object System.Text.StringBuilder
function Out($text) {
    $null = $sb.AppendLine($text)
    Write-Output $text
}

# Header
Out("Full Windows + Hardware Specification Report")
Out("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
Write-Section "Operating System"

# OS Info
Safe-Get {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $comp = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
    $ci = @{}
    $ci.ProductName = (Get-ComputerInfo -Property "OsName" -ErrorAction SilentlyContinue).OsName
    if (-not $ci.ProductName) { $ci.ProductName = $os.Caption }
    $ci.Version = $os.Version
    $ci.BuildNumber = $os.BuildNumber
    $ci.InstallDate = ($os.InstallDate -as [datetime]).ToLocalTime()
    $ci.LastBoot = ($os.LastBootUpTime -as [datetime]).ToLocalTime()
    $ci.OSArchitecture = $os.OSArchitecture
    $ci.ComputerName = $env:COMPUTERNAME
    $ci.Domain = $comp.Domain
    $ci.SerialNumber = (Get-CimInstance -Class Win32_BIOS -ErrorAction SilentlyContinue).SerialNumber
    Out("Product: $($ci.ProductName)")
    Out("Version: $($ci.Version)    Build: $($ci.BuildNumber)    Architecture: $($ci.OSArchitecture)")
    Out("Install Date: $($ci.InstallDate)    Last Boot: $($ci.LastBoot)")
    Out("Computer Name: $($ci.ComputerName)    Domain: $($ci.Domain)")
    Out("System Serial: $($ci.SerialNumber)")
}

# Windows edition and license status (best-effort)
Safe-Get {
    $edition = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).EditionID
    if ($edition) { Out("EditionID (registry): $edition") }
    $activation = (Get-CimInstance -Namespace root\cimv2 -ClassName SoftwareLicensingProduct -Filter "PartialProductKey IS NOT NULL AND LicenseIsAddon=0" -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -like "Windows*" } | Select-Object -First 1)
    if ($activation) {
        Out("License/Product: $($activation.Name)    LicenseStatus: $($activation.LicenseStatus)")
    }
}

Write-Section "System (Chassis / Mainboard / BIOS)"
Safe-Get {
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $base = Get-CimInstance -ClassName Win32_BaseBoard
    $cs = Get-CimInstance -ClassName Win32_ComputerSystem
    Out("Manufacturer: $($cs.Manufacturer)    Model: $($cs.Model)")
    Out("System Type: $($cs.SystemType)    Total Physical Memory: $([math]::Round($cs.TotalPhysicalMemory/1GB,2)) GB")
    Out("Baseboard Manufacturer: $($base.Manufacturer)    Product: $($base.Product)    Version: $($base.Version)")
    Out("BIOS Vendor: $($bios.Manufacturer)    BIOS Version: $($bios.SMBIOSBIOSVersion)")
    Out("BIOS Release Date: $($bios.ReleaseDate -as [datetime])    Serial: $($bios.SerialNumber)")
}

Write-Section "Processors (CPU)"
Safe-Get {
    $cpus = Get-CimInstance -ClassName Win32_Processor
    $i = 0
    foreach ($cpu in $cpus) {
        $i++
        Out("CPU #$i: $($cpu.Name)    Manufacturer: $($cpu.Manufacturer)    Cores: $($cpu.NumberOfCores)    LogicalProc: $($cpu.NumberOfLogicalProcessors)    MaxClockMHz: $($cpu.MaxClockSpeed) MHz")
        Out("  Socket: $($cpu.SocketDesignation)    ID: $($cpu.DeviceID)    CurrentClock: $($cpu.CurrentClockSpeed) MHz")
    }
}

Write-Section "Memory (RAM modules)"
Safe-Get {
    $memModules = Get-CimInstance -ClassName Win32_PhysicalMemory | Sort-Object -Property BankLabel
    $total = 0
    $idx = 0
    foreach ($m in $memModules) {
        $idx++
        $sizeGB = [math]::Round($m.Capacity/1GB,3)
        $total += $m.Capacity
        Out("Module $idx: Bank=$($m.BankLabel) DevLocator=$($m.DeviceLocator) Size=${sizeGB}GB Type=$($m.MemoryType) Speed=$($m.Speed)MHz Manufacturer=$($m.Manufacturer) PartNumber=$($m.PartNumber) Serial=$($m.SerialNumber)")
    }
    if ($memModules) { Out("Total Physical RAM: $([math]::Round($total/1GB,3)) GB") } else { Out("No physical memory module info available via WMI.") }
}

Write-Section "Graphics (GPU)"
Safe-Get {
    $gpus = Get-CimInstance -ClassName Win32_VideoController
    $i = 0
    foreach ($g in $gpus) {
        $i++
        Out("GPU #$i: $($g.Name)    AdapterRAM: $([math]::Round($g.AdapterRAM/1MB)) MB    DriverVersion: $($g.DriverVersion)    VideoProcessor: $($g.VideoProcessor)")
    }
}

Write-Section "Storage (Physical Disks)"
Safe-Get {
    # Prefer the Storage module (Get-PhysicalDisk) if available
    if (Get-Command Get-PhysicalDisk -ErrorAction SilentlyContinue) {
        $pds = Get-PhysicalDisk -ErrorAction SilentlyContinue
        if ($pds) {
            foreach ($d in $pds) {
                Out("PD: FriendlyName=$($d.FriendlyName) Serial=$($d.SerialNumber) MediaType=$($d.MediaType) SizeGB=$([math]::Round($d.Size/1GB,2)) Health=$($d.HealthStatus) Operational=$($d.OperationalStatus)")
            }
        }
    }
    # Fallback to Win32_DiskDrive
    $drives = Get-CimInstance -ClassName Win32_DiskDrive
    $i=0
    foreach ($dd in $drives) {
        $i++
        Out("Disk #$i: Model=$($dd.Model) Interface=$($dd.InterfaceType) SizeGB=$([math]::Round($dd.Size/1GB,2)) Serial=$($dd.SerialNumber) MediaType=$($dd.MediaType)")
    }

    Write-Output ""
    Out("Partitions & Volumes:")
    $vols = Get-Volume -ErrorAction SilentlyContinue
    if ($vols) {
        foreach ($v in $vols) {
            Out("  DriveLetter=$($v.DriveLetter)  Label='$($v.FileSystemLabel)'  FS=$($v.FileSystem)  Size=$([math]::Round($v.Size/1GB,2))GB  Free=$([math]::Round($v.SizeRemaining/1GB,2))GB  Health=$($v.HealthStatus)")
        }
    } else {
        # fallback to Win32_LogicalDisk
        $ld = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
        foreach ($l in $ld) {
            Out("  $($l.DeviceID)  FS=$($l.FileSystem)  Size=$([math]::Round($l.Size/1GB,2))GB  Free=$([math]::Round($l.FreeSpace/1GB,2))GB")
        }
    }
}

Write-Section "Network Adapters"
Safe-Get {
    $nics = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Sort-Object -Property Name
    if ($nics) {
        foreach ($nic in $nics) {
            $ifIndex = $nic.ifIndex
            $ipcfg = Get-NetIPAddress -InterfaceIndex $ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.PrefixOrigin -ne "WellKnown" }
            $ips = if ($ipcfg) { ($ipcfg | ForEach-Object { "$($_.IPAddress)/$($_.PrefixLength)" }) -join ", " } else { "<no ipv4>" }
            Out("NIC: $($nic.Name)    Status=$($nic.Status)    LinkSpeed=$($nic.LinkSpeed)    MAC=$($nic.MacAddress)    IP=$ips")
        }
    } else {
        # fallback WMI
        $configs = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        foreach ($c in $configs) {
            Out("NIC: $($c.Description)    MAC=$($c.MACAddress)    IP=$($c.IPAddress -join ', ')")
        }
    }
}

Write-Section "Other (USB, TPM, Virtualization)"
Safe-Get {
    # TPM
    try {
        $tpm = Get-CimInstance -Namespace root\CIMV2\Security\MicrosoftTpm -ClassName Win32_Tpm -ErrorAction SilentlyContinue
        if ($tpm) {
            Out("TPM Present: $($tpm.IsEnabled_InitialValue)  SpecVersion: $($tpm.SpecVersion)")
        } else {
            Out("TPM: not reported via CIM.")
        }
    } catch {
        Out("TPM: not available or access denied.")
    }

    # Virtualization support
    try {
        $vir = Get-CimInstance -ClassName Win32_ComputerSystem
        $virt = if ($vir.PartOfDomain -eq $false -and $vir.Model -match "Virtual") { $true } else { $false }
        Out("Hypervisor Present (Indication): $virt  Manufacturer reported model: $($vir.Model)")
    } catch { Out("Virtualization: unknown") }

    # USB devices (basic)
    $usb = Get-CimInstance -Class Win32_USBControllerDevice -ErrorAction SilentlyContinue | ForEach-Object {
        $pn = ($_.Dependent -split '"')[1]   # best-effort
        $pn
    } | Select-Object -Unique
    if ($usb) {
        Out("USB devices (partial list):")
        foreach ($u in $usb) { Out("  $u") }
    } else {
        Out("USB devices: none enumerated (or insufficient permissions).")
    }
}

Write-Section "Installed Hotfixes (recent)"
Safe-Get {
    # limited list for brevity (last 10)
    try {
        $hotfixes = Get-HotFix -ErrorAction SilentlyContinue | Sort-Object -Property InstalledOn -Descending | Select-Object -First 10
        foreach ($h in $hotfixes) {
            Out("KB: $($h.HotFixID)  InstalledOn: $($h.InstalledOn.ToShortDateString())  Source: $($h.Source)")
        }
    } catch {
        Out("Installed updates: unable to enumerate with Get-HotFix.")
    }
}

# Optional export
if ($OutputFile) {
    try {
        $sb.ToString() | Out-File -FilePath $OutputFile -Encoding UTF8 -Force
        Write-Output ""
        Write-Output "Report saved to: $OutputFile"
    } catch {
        Write-Output ""
        Write-Output "Failed to write report to $OutputFile: $($_.Exception.Message)"
    }
}

# End
Out("")
Out("End of report.")
