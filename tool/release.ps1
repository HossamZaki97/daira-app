# Build the store app (com.daira.circles, "Daira") as a signed Android App Bundle.
#   1. Set ODOO_URL in config/prod.json to the production server (HTTPS).
#   2. Raise "version:" in pubspec.yaml (e.g. 2.0.1+2 - the number after + must grow every upload).
#   3. .\tool\release.ps1   -> build\app\outputs\bundle\prodRelease\app-prod-release.aab
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$config = Get-Content 'config/prod.json' -Raw | ConvertFrom-Json
if ($config.ODOO_URL -notmatch '^https://' -or $config.ODOO_URL -match 'CHANGE-ME') {
  throw 'Set the production HTTPS address in config/prod.json (ODOO_URL) first.'
}
if (-not (Test-Path 'android/key.properties')) { throw 'No signing key. Run .\tool\make-keystore.ps1 once.' }
if (-not (Test-Path 'android/app/google-services.json')) { throw 'android/app/google-services.json is missing (Firebase).' }
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'Fix the analyzer issues first.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
flutter build appbundle --release --flavor prod --dart-define-from-file=config/prod.json --split-debug-info=build/symbols
Write-Host ''
Write-Host 'Upload: build\app\outputs\bundle\prodRelease\app-prod-release.aab'
Write-Host 'Keep build\symbols (crash symbols) for this version.'
