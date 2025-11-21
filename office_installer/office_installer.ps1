# Windows 11 Office Installer using Microsoft ODT
# Run as Administrator

Write-Host "Downloading Office Deployment Tool..." -ForegroundColor Cyan

$odtUrl = "https://download.microsoft.com/download/2/2/3/2230A6A1-5229-4D59-9F9A-7F67A75B8B2A/officedeploymenttool_16425-20210.exe"
$odtExe = "$env:TEMP\ODT.exe"

Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe

Write-Host "Extracting ODT..." -ForegroundColor Cyan
$odtFolder = "$env:TEMP\ODT"
Start-Process -FilePath $odtExe -ArgumentList "/quiet", "/extract:$odtFolder" -Wait

# Create configuration file for Microsoft 365 Apps (Office 365)
$configXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us"/>
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE"/>
  <Updates Enabled="TRUE"/>
</Configuration>
"@

$configFile = "$odtFolder\config.xml"
$configXml | Out-File -FilePath $configFile -Encoding UTF8

Write-Host "Installing Microsoft Office for Windows 11..." -ForegroundColor Yellow
Start-Process -FilePath "$odtFolder\setup.exe" -ArgumentList "/configure config.xml" -Wait

Write-Host "Office installation complete!" -ForegroundColor Green
