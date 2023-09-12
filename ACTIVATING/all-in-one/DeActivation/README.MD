## DeActivation

In PowerShell - administrator

```cmd
Open a command prompt as an Administrator.

Enter slmgr /upk ### and wait for this to complete. This will uninstall the current product key from Windows and put it into an unlicensed state.

Enter slmgr /cpky ### and wait for this to complete. This will remove the product key from the registry if it's still there.

Enter slmgr /rearm ### and wait for this to complete. This is to reset the Windows activation timers so the new users will be prompted to activate Windows when they put in the key.
```
