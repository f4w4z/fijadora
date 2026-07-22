$ErrorActionPreference = 'Stop'
$sdk  = "$env:LOCALAPPDATA\Android\Sdk"
$adb  = "$sdk\platform-tools\adb.exe"
$root = "C:\Projects\Fijadora"
    $apps = @("customer_app", "staff_app", "worker_app")
    $pkgs = @{
      "customer_app" = "com.fijadora.customer_app"
      "staff_app"    = "com.fijadora.staff_app"
      "worker_app"   = "com.fijadora.worker_app"
    }

$avd  = "Pixel_9"
$log  = Join-Path $root "install-log.txt"

# Credentials must match those in run.ps1
$SUPABASE_URL       = "https://nmcxkoahokihzqnfkmvg.supabase.co"
$SUPABASE_ANON_KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5tY3hrb2Fob2tpaHpxbmZrbXZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI5MTUyNDYsImV4cCI6MjA5ODQ5MTI0Nn0.dLuCnzb2bvwHrFC7lGmH1k1qTQrv15vmwQHSh6cXnNU"
$SENTRY_DSN         = "https://13c9f2cf435c2b3bba6d7c9fe7a20e0c@o4511661062291456.ingest.de.sentry.io/4511661103513680"
$OPENROUTER_MODEL    = "google/gemini-2.0-flash-lite-001"

$dartDefines = @(
  "--dart-define=SUPABASE_URL=$SUPABASE_URL",
  "--dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY",
  "--dart-define=SENTRY_DSN=$SENTRY_DSN",
  "--dart-define=OPENROUTER_MODEL=$OPENROUTER_MODEL",
  "--dart-define=APP_ENV=development"
)

Start-Transcript -Path $log -Append | Out-Null
Write-Host "$(Get-Date) Starting install of all apps"

# ── Progress-bar helper (host-native bar + ASCII bar for the log) ──────────────
function Write-Bar {
    param(
        [int]    $Percent,
        [string] $Label,
        [int]    $Id = 1,
        [int]    $ParentId = -1
    )
    $Percent = [math]::Max(0, [math]::Min(100, $Percent))
    $w      = 40
    $filled  = [math]::Floor($w * $Percent / 100)
    $bar    = ('#' * $filled) + ('-' * ($w - $filled))
    Write-Host ("[{0}] {1,3}%  {2}" -f $bar, $Percent, $Label)
    if ($ParentId -ge 0) {
        Write-Progress -Id $Id -ParentId $ParentId -Activity 'Installing Fijadora apps' -Status $Label -PercentComplete $Percent
    } else {
        Write-Progress -Id $Id -Activity 'Installing Fijadora apps' -Status $Label -PercentComplete $Percent
    }
}

function Ensure-Emulator {
    $devs = & $adb devices 2>$null
    if ($devs -match 'emulator-\d+\s+device') { Write-Host "Emulator already online"; return }

    Write-Host "Launching emulator..."
    $p = New-Object System.Diagnostics.ProcessStartInfo
    $p.FileName    = "$sdk\emulator\emulator.exe"
    $p.Arguments   = "-avd $avd -netdelay none -netspeed full"
    $p.CreateNoWindow = $true
    $p.WindowStyle   = 'Normal'
    $p.UseShellExecute = $false
    [System.Diagnostics.Process]::Start($p) | Out-Null

    for ($i = 0; $i -lt 60; $i++) {
        Start-Sleep -Seconds 5
        $d = & $adb devices 2>$null
        if ($d -match 'emulator-\d+\s+device') { Write-Host "Emulator online"; return }
    }
    throw "Emulator did not come online in time"
}

Ensure-Emulator

$total = $apps.Count
for ($i = 0; $i -lt $total; $i++) {
    $app = $apps[$i]
    $dir = Join-Path $root "apps\$app"
    $overall = [int](($i / $total) * 100)
    Write-Bar -Percent $overall -Label "Starting $app ($($i+1)/$total)" -Id 1
    Push-Location $dir
    try {
        Write-Host "===== Building $app ====="
        Write-Bar -Percent ([int](($i + 0.25) / $total * 100)) -Label "Building $app" -Id 2 -ParentId 1
        flutter build apk --release --split-per-abi @dartDefines
        $apkDir = Join-Path $dir "build\app\outputs\flutter-apk"
        # Prefer the architecture that matches the emulator/device (arm64-v8a),
        # then fall back to any split APK, then the universal fat APK.
        $apk = @(
          Join-Path $apkDir 'app-arm64-v8a-release.apk'
          Join-Path $apkDir 'app-armeabi-v7a-release.apk'
          Join-Path $apkDir 'app-x86_64-release.apk'
          Join-Path $apkDir 'app-release.apk'
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $apk) { throw "APK not found in $apkDir" }

        Write-Bar -Percent ([int](($i + 0.6) / $total * 100)) -Label "Uninstalling previous $app" -Id 2 -ParentId 1
        Write-Host "===== Uninstalling previous $app ====="
        & $adb shell am force-stop $pkgs[$app] 2>$null
        & $adb uninstall $pkgs[$app] 2>$null

        Write-Bar -Percent ([int](($i + 0.8) / $total * 100)) -Label "Installing $app" -Id 2 -ParentId 1
        Write-Host "===== Installing $app ====="
        & $adb install -r $apk
        if ($LASTEXITCODE -ne 0) { throw "adb install failed for $app" }
        Write-Host "===== $app installed OK ====="
    } finally {
        Pop-Location
    }
    Write-Bar -Percent ([int](($i + 1) / $total * 100)) -Label "$app done ($($i+1)/$total)" -Id 2 -ParentId 1
}

Write-Bar -Percent 100 -Label "All three apps installed successfully" -Id 1
Write-Progress -Id 1 -Activity 'Installing Fijadora apps' -Completed
Write-Progress -Id 2 -Activity 'Installing Fijadora apps' -Completed
Write-Host "$(Get-Date) All three apps installed successfully"
Stop-Transcript | Out-Null
