:: nu11seur1ty-2023
@echo off
net stop wuauserv 
net stop cryptSvc 
net stop bits 
ren C:\Windows\SoftwareDistribution SoftwareDistribution.old 
ren C:\Windows\System32\catroot2 Catroot2.old 
net start wuauserv 
net start cryptSvc 
net start bits 
rmdir /s /q C:\Windows\SoftwareDistribution.old 
rmdir /s /q C:\Windows\System32\Catroot2.old
netsh winsock reset
shutdown /R
