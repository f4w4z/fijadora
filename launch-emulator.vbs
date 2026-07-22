Set oShell = CreateObject("WScript.Shell")

sdk = oShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Android\Sdk"

cmd = "powershell -NoProfile -WindowStyle Hidden -Command " & _
      """$p=New-Object System.Diagnostics.ProcessStartInfo; " & _
      "$p.FileName='" & sdk & "\emulator\emulator.exe'; " & _
      "$p.Arguments='-avd Pixel_9 -netdelay none -netspeed full'; " & _
      "$p.CreateNoWindow=$true; $p.WindowStyle='Normal'; " & _
      "$p.UseShellExecute=$false; " & _
      "[System.Diagnostics.Process]::Start($p) | Out-Null"""

oShell.Run cmd, 0, False
