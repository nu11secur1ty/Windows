cmd /c echo y | powershell "read-host" Set-ExecutionPolicy RemoteSigned
Get-AppxPackage -allusers Microsoft.549981C3F5F10 | Remove-AppxPackage
cmd /c echo y | powershell "read-host" Set-ExecutionPolicy Restricted
