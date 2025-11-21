# ============================
# Office Auto Installer (Fixed)
# ============================

Write-Host "Downloading Office Deployment Tool..."

$odtUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18526-20146.exe"

$temp = [IO.Path]::GetTempPath()
$odtExe = Join-Path $temp "odt-setup.exe"
$odtFolder = Join-Path $temp "ODT"

# Download ODT
Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe

# Prepare folder
if (-Not (Test-Path $odtFolder)) {
    New-Item $odtFolder -ItemType Directory | Out-Null
}

# Extract ODT
Write-Host "Extracting ODT..."
Start-Process -FilePath $odtExe -ArgumentList "/quiet", "/extract:$odtFolder" -Wait

# Create config XML
$configFile = Join-Path $odtFolder "configuration.xml"

$configXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
</Configuration>
"@

$configXml | Out-File -FilePath $configFile -Encoding UTF8

# Install Office
$setupExe = Join-Path $odtFolder "setup.exe"

Write-Host "Installing Microsoft Office..."
Start-Process -FilePath $setupExe -ArgumentList "/configure", $configFile -Wait

Write-Host "Office installation complete!"
