Set oShell = CreateObject("WScript.Shell")
ps = "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File ""C:\Projects\Fijadora\install-apps.ps1"""
oShell.Run ps, 0, True
MsgBox "Fijadora: all three apps installed (or check install-log.txt).", 0, "Fijadora Installer"
