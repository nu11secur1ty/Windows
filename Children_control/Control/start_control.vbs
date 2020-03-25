Option Explicit
 
Dim i, strArguments, wshShell
 
If WScript.Arguments.Count = 0 Then Syntax
If WScript.Arguments(0) = "/?" Then Syntax
 
strArguments = ""
 
For i = 0 To WScript.Arguments.Count - 1
	strArguments = strArguments & " " & WScript.Arguments(i)
Next
 
Set wshShell = CreateObject( "WScript.Shell" )
wshShell.Run Trim( strArguments ), 0, False
Set wshShell = Nothing
 
 
Sub Syntax
	Dim strMsg
	strMsg = "RunNHide.vbs,  Version 3.00" & vbCrLf _
	       & "http://nu11secur1ty.com"
	WScript.Echo strMsg
	WScript.Quit 1
End Sub
