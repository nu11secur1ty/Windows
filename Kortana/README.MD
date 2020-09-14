# kortakill
Run on PowerShell as Administrator

- - - Enable execution of scripts on your system.
```cmd
cmd /c echo y | powershell "read-host" Set-ExecutionPolicy RemoteSigned
```
- - - Uninstall kortana
```cmd
.\kortakill.exe
```
![](https://github.com/nu11secur1ty/Windows/blob/master/Kortana/screen/korakill.PNG)

- - - Check
[Checking](https://www.microsoft.com/en-us/p/cortana/9nffx4szz23l?ranMID=24542&ranEAID=kXQk6*ivFEQ&ranSiteID=kXQk6.ivFEQ-O7aV1auvI7b2DoVXI0IUJQ&epi=kXQk6.ivFEQ-O7aV1auvI7b2DoVXI0IUJQ&irgwc=1&OCID=AID2000142_aff_7593_1243925&tduid=%28ir__1zd9xsqz2skftwktkk0sohz3zv2xi6mt6xgpu1q200%29%287593%29%281243925%29%28kXQk6.ivFEQ-O7aV1auvI7b2DoVXI0IUJQ%29%28%29&irclickid=_1zd9xsqz2skftwktkk0sohz3zv2xi6mt6xgpu1q200&activetab=pivot%3Aoverviewtab)

- - - After you finish with installation of kortakill, you can turnbacjk the policy
```cmd
cmd /c echo y | powershell "read-host" Set-ExecutionPolicy Restricted
```
