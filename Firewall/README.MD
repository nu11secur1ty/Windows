## Block traffic
![](https://github.com/nu11secur1ty/Windows/blob/master/Firewall/docs/wall.jpg)

- Usage
-   
## Block from CIDR
```powershell
.\import-firewall-blocklist.ps1 -InputFile .\blacklist.txt
```
## Delete Rule
```powershell
.\import-firewall-blocklist.ps1 -InputFile .\blacklist.txt -deleteonly
```
## Reset and delete
```powershell
Remove-NetFirewallRule -All
(New-Object -ComObject HNetCfg.FwPolicy2).RestoreLocalFirewallDefaults()
```
