# Capture the main window of a running process to a PNG (used to check the
# rebuilt UI against the Figma frames).
#   powershell -File scripts/capture-window.ps1 -ProcessName vlc -Out shot.png [-Width 1600 -Height 900]
param(
    [string]$ProcessName = "vlc",
    [string]$PathLike = "*",
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Width = 0,
    [int]$Height = 0
)

Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class JuxtWin {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hgt, bool repaint);
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int hgt, uint flags);
}
"@
[JuxtWin]::SetProcessDPIAware() | Out-Null

$proc = Get-Process -Name $ProcessName -ErrorAction Stop |
    Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero -and $_.Path -like $PathLike } | Select-Object -First 1
if (-not $proc) { throw "no window for $ProcessName" }
$h = $proc.MainWindowHandle

[JuxtWin]::ShowWindow($h, 9) | Out-Null   # SW_RESTORE
if ($Width -gt 0 -and $Height -gt 0) { [JuxtWin]::MoveWindow($h, 40, 40, $Width, $Height, $true) | Out-Null }
[JuxtWin]::SetForegroundWindow($h) | Out-Null
# Windows may refuse to give us the foreground; keep the window on top anyway
# while capturing (HWND_TOPMOST, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE).
[JuxtWin]::SetWindowPos($h, [IntPtr](-1), 0, 0, 0, 0, 0x13) | Out-Null
Start-Sleep -Milliseconds 800

$r = New-Object JuxtWin+RECT
[JuxtWin]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.Right - $r.Left; $hh = $r.Bottom - $r.Top
$bmp = New-Object System.Drawing.Bitmap $w, $hh
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
[JuxtWin]::SetWindowPos($h, [IntPtr](-2), 0, 0, 0, 0, 0x13) | Out-Null   # HWND_NOTOPMOST
"captured ${w}x${hh} -> $Out"
