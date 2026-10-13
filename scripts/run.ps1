# Launch the rebuilt VLC in portable mode (profile in dist\vlc\portable, so an
# installed VLC's settings are neither used nor modified), optionally capture
# the window and print Qt/QML warnings from the log.
#   powershell -File scripts/run.ps1 [-Media file] [-Shot out.png] [-Wait 7] [-Args ...]
param(
    [string]$Media = "",
    [string]$Shot = "",
    [int]$Wait = 7,
    [int]$Width = 1600,
    [int]$Height = 900,
    [string[]]$Args = @(),
    [switch]$KeepProfile
)

$root = Split-Path -Parent $PSScriptRoot
$vlcDir = Join-Path $root "dist\vlc"
# VLC switches to portable mode when this folder exists next to vlc.exe
# (src/win32/dirs.c); it ignores %APPDATA% overrides.
$profileDir = Join-Path $vlcDir "portable"
$log = Join-Path $root "dist\vlc-log.txt"

Get-Process vlc -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -like "$vlcDir*" } | Stop-Process -Force
Start-Sleep -Milliseconds 500
if (-not $KeepProfile -and (Test-Path $profileDir)) { Remove-Item -Recurse -Force $profileDir }
New-Item -ItemType Directory -Force $profileDir | Out-Null
Remove-Item $log -ErrorAction SilentlyContinue

$vlcArgs = @("--no-qt-privacy-ask", "--no-qt-updates-notif", "--verbose=2",
             "--file-logging", "--logfile=$log") + $Args
if ($Media) { $vlcArgs += $Media }
Start-Process -FilePath (Join-Path $vlcDir "vlc.exe") -ArgumentList $vlcArgs | Out-Null
Start-Sleep -Seconds $Wait

if ($Shot) {
    & (Join-Path $PSScriptRoot "capture-window.ps1") -ProcessName vlc -PathLike "$vlcDir*" -Out $Shot -Width $Width -Height $Height
}

if (Test-Path $log) {
    Select-String -Path $log -Pattern "\.qml:\d+|qt warning|qt error" |
        ForEach-Object { $_.Line.Substring(0, [Math]::Min(300, $_.Line.Length)) }
}
