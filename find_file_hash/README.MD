 # For example I will check the hash key of notepad.exe which is already installed
 1. - Open PowerShell as Administrator
 - install the software `get-filehas`
 
 ```cmd
 get-help get-filehash
 ```
 - Choice `Y`
 
2. After installing the software you can check for your hash =) 
 ```cmd
 Get-FileHash 'C:\Program Files (x86)\Notepad++\notepad++.exe' | Format-List
 ```
 
 3. Save HASH 
 - Open Notepad, and save your hash, for example: 
 add in to a user.txt `38BAA3FF72CF43F016A9D0DF9E7CB6C1SDA7481B5F2AE2F599AD53DDDEC87317`
 save and quit.
 
 # BR nu11secur1ty
