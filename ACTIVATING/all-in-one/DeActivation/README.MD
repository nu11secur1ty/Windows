## DeActivation

PowerShell as an Administrator.

## and wait for this to complete. This will uninstall the current product key from Windows and put it into an unlicensed state.
```cmd
Enter slmgr /upk 
```
## and wait for this to complete. This will remove the product key from the registry if it's still there.
```cmd
Enter slmgr /cpky 
```
## and wait for this to complete. This is to reset the Windows activation timers so the new users will be prompted to activate Windows when they put in the key.
```cmd
Enter slmgr /rearm 
```
