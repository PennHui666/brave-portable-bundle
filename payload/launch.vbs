Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
dir = fso.GetParentFolderName(WScript.ScriptFullName)
wrapper = dir & "\brave-portable.exe"
progid = "BravePortableHTML"
client = "BravePortable"

If Not fso.FileExists(wrapper) Then
    sh.Popup "Launcher not found: " & wrapper, 0, "Brave Portable", 16
    WScript.Quit 1
End If

On Error Resume Next
cur = sh.RegRead("HKCU\Software\Classes\" & progid & "\shell\open\command\")
On Error Goto 0

If cur <> "" Then
    If InStr(1, cur, wrapper, 1) = 0 Then
        sh.RegWrite "HKCU\Software\Classes\" & progid & "\shell\open\command\", """" & wrapper & """ ""%1""", "REG_SZ"
        sh.RegWrite "HKCU\Software\Classes\" & progid & "\DefaultIcon\", """" & wrapper & """,0", "REG_SZ"
        sh.RegWrite "HKCU\Software\Clients\StartMenuInternet\" & client & "\shell\open\command\", """" & wrapper & """", "REG_SZ"
        sh.RegWrite "HKCU\Software\Clients\StartMenuInternet\" & client & "\DefaultIcon\", """" & wrapper & """,0", "REG_SZ"
    End If
End If

args = ""
For i = 0 To WScript.Arguments.Count - 1
    args = args & " """ & WScript.Arguments(i) & """"
Next
sh.Run """" & wrapper & """" & args, 1, False