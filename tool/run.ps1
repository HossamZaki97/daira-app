# Run the dev app (com.daira.circles.dev, "Daira Dev") on a USB-connected
# Android phone against the local Odoo. The phone reaches the computer's Odoo
# (127.0.0.1:8019) through an adb tunnel that is lost whenever the phone is
# unplugged or adb restarts, so it is opened on every run.
#   .\tool\run.ps1            (extra flutter args are passed through)
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
if (-not (Test-Path 'config/local.json')) { Copy-Item 'config/local.example.json' 'config/local.json' }
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { $adb = 'adb' }
& $adb reverse tcp:8019 tcp:8019
try {
  Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 http://127.0.0.1:8019/daira/health | Out-Null
  Write-Host 'Odoo is running on 127.0.0.1:8019'
} catch {
  Write-Warning 'Odoo does not answer on 127.0.0.1:8019 - start it from PyCharm first.'
}
flutter run --flavor dev --dart-define-from-file=config/local.json --dart-define=APP_SCHEME=daira-dev @args
