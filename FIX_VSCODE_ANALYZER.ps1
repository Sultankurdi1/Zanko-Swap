# ZankoSwap - repair Dart/Flutter analyzer resolution
$ErrorActionPreference = "Stop"

Write-Host "Checking Flutter SDK..."
flutter --version

Write-Host "`nCleaning project-local generated files..."
flutter clean

if (Test-Path ".dart_tool") {
    Remove-Item -Recurse -Force ".dart_tool"
}
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
}

Write-Host "`nFetching packages..."
flutter pub get

Write-Host "`nDone."
Write-Host "Now restart VS Code analysis:"
Write-Host "  Ctrl+Shift+P -> Dart: Restart Analysis Server"
Write-Host "Then reopen the ZankoSwap folder itself (not only a single Dart file)."
