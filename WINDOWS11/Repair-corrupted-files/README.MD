### Repair corrupted files
- Run as administrator

### Type the following DISM command to repair corrupted system files and press Enter:

```cmd
dism.exe /Online /Cleanup-image /Restorehealth
```

### Type the following SFC command to repair system files and press Enter:

```cmd
sfc /scannow
```
