@ECHO OFF
:@nu11secur1ty

SET /P uname=Please enter 1 to continue... 
IF "%uname%"=="" GOTO Error
net use 

SET /P uname=Please enter your SMB share connect:
IF "%uname%"=="" GOTO Error
cmdkey /delete %uname%
	pause
shutdown /r

GOTO End

:Error
ECHO You did not enter 1! Bye bye!!
:End
