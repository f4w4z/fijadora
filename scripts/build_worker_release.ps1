# Builds a release APK for the Worker app.
# Run from the repo root:  .\scripts\build_worker_release.ps1
# Requires: Flutter SDK on PATH, Android SDK configured.

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$appDir   = Join-Path $repoRoot 'apps\worker_app'
$outDir   = Join-Path $appDir 'build\app\outputs\flutter-apk'

Write-Host "==> Cleaning worker_app" -ForegroundColor Cyan
Set-Location $appDir
flutter clean

Write-Host "==> Getting packages" -ForegroundColor Cyan
flutter pub get

Write-Host "==> Building release APK (worker_app)" -ForegroundColor Cyan
flutter build apk --release --split-per-abi --target lib\main.dart

Write-Host "==> Done. APKs at: $outDir (app-arm64-v8a-release.apk, app-armeabi-v7a-release.apk, app-x86_64-release.apk)" -ForegroundColor Green
Set-Location $repoRoot
