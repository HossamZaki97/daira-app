# Create the Android upload key ONCE and write android/key.properties (both kept out of git).
# The key file goes to your user folder, not the project. Back up the .jks file and the
# password somewhere safe: without them you can never update the app on Google Play.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$dir = Join-Path $env:USERPROFILE '.daira'
$jks = Join-Path $dir 'daira-upload.jks'
if (Test-Path $jks) { throw "A key already exists: $jks (delete it only if you are sure)." }
New-Item -ItemType Directory -Force -Path $dir | Out-Null
$secure = Read-Host 'Choose a key password (at least 8 characters)' -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
if ($password.Length -lt 8) { throw 'Password too short.' }
$keytool = 'keytool'
if ($env:JAVA_HOME) { $keytool = Join-Path $env:JAVA_HOME 'bin\keytool.exe' }
& $keytool -genkeypair -v -keystore $jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload -storepass $password -keypass $password -dname 'CN=Daira, O=Daira, C=EG'
@"
storeFile=$($jks -replace '\\','/')
storePassword=$password
keyAlias=upload
keyPassword=$password
"@ | Set-Content -Encoding ASCII 'android/key.properties'
Write-Host "Key created: $jks"
Write-Host 'android/key.properties written (ignored by git). Back up the .jks file and the password now.'
