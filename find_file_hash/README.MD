 # For example I will check the hash key of notepad++.exe which is alredy instaled
 1. - Open PowerShell as Administrator
 - install the software `get-filehas`
 
 ```cmd
 get-filehash
 ```
 - Choice `Y`
 
2. After installing the software you can check for your hash =) 
 ```cmd
 Get-FileHash 'C:\Program Files (x86)\Notepad++\notepad++.exe' | Format-List
 ```
 
 # BR nu11secur1ty
