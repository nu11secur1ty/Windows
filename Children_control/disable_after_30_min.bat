@echo on
timeout /t 1800
netsh interface set interface "Wi-Fi" disable
netsh interface set interface "Local Area Connection" disable
