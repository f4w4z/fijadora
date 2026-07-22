# Builds release APKs for all three apps sequentially.
# Run from the repo root:  .\scripts\build_all_release.ps1
# Requires: Flutter SDK on PATH, Android SDK configured.

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')

$apps = @('customer_app', 'worker_app', 'staff_app')

foreach ($app in $apps) {
  Write-Host "`n========== Building $app ==========" -ForegroundColor Magenta
  & "$PSScriptRoot\build_$($app -replace '_app','_release').ps1"
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed for $app" -ForegroundColor Red
    exit 1
  }
}

Write-Host "`n========== All builds complete ==========" -ForegroundColor Green
foreach ($app in $apps) {
  $apkDir = Join-Path $repoRoot "apps\$app\build\app\outputs\flutter-apk"
  $apks   = Get-ChildItem -Path $apkDir -Filter 'app-*-release.apk' -ErrorAction SilentlyContinue
  if ($apks) {
    foreach ($apk in $apks) {
      $size = $apk.Length / 1MB
      Write-Host ("  {0,-12} -> {1}  ({2:N1} MB)" -f $app, $apk.Name, $size) -ForegroundColor White
    }
  } else {
    Write-Host ("  {0,-12} -> MISSING" -f $app) -ForegroundColor Red
  }
}
