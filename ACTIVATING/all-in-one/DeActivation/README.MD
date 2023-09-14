## DeActivation

PowerShell as an Administrator.

## This will uninstall the current product key from Windows and put it into an unlicensed state.
```cmd
slmgr /upk 
```
## This will remove the product key from the registry if it's still there.
```cmd
slmgr /cpky 
```
## This is to reset the Windows activation timers so the new users will be prompted to activate Windows when they put in the key.
```cmd
slmgr /rearm 
```
