# check info
# Note:
RUN AS ADMINISTRATOR
- usage with powershell:
```
1. Set-ExecutionPolicy Bypass -Scope Process -Force
1. iex (iwr 'https://raw.githubusercontent.com/nu11secur1ty/Windows/master/check_info/Get-FullWindowsHardwareInfo.ps1' -UseBasicParsing | Select-Object -ExpandProperty Content)
```
