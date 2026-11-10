# Run the app on a USB-connected Android phone against the local Odoo.
# The phone reaches the computer's Odoo (127.0.0.1:8019) through an adb tunnel,
# which is lost whenever the phone is unplugged or adb restarts.
#   .\tool\run.ps1            (extra flutter args are passed through)
$ErrorActionPreference = 'Stop'
$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path $adb)) { $adb = 'adb' }
& $adb reverse tcp:8019 tcp:8019
try {
  Invoke-WebRequest -UseBasicParsing -TimeoutSec 5 http://127.0.0.1:8019/daira/health | Out-Null
  Write-Host 'Odoo is running on 127.0.0.1:8019'
} catch {
  Write-Warning 'Odoo does not answer on 127.0.0.1:8019 - start it from PyCharm first.'
}
flutter run --dart-define-from-file=config/local.json @args
