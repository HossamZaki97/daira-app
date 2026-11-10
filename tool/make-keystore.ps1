# Create the Android upload key ONCE and write android/key.properties (both kept out of git).
# The key file goes to your user folder, not the project. Back up the .jks file and the
# password somewhere safe: without them you can never update the app on Google Play.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$dir = Join-Path $env:USERPROFILE '.daira'
$jks = Join-Path $dir 'daira-upload.jks'
if (Test-Path $jks) { throw "A key already exists: $jks (delete it only if you are sure)." }
New-Item -ItemType Directory -Force -Path $dir | Out-Null
# keytool ships with Java. Look in JAVA_HOME, Android Studio's bundled Java, then ask Flutter.
function Find-Keytool {
  $candidates = @()
  if ($env:JAVA_HOME) { $candidates += Join-Path $env:JAVA_HOME 'bin\keytool.exe' }
  $candidates += @(
    "$env:ProgramFiles\Android\Android Studio\jbr\bin\keytool.exe",
    "$env:ProgramFiles\Android\Android Studio\jre\bin\keytool.exe",
    "$env:LOCALAPPDATA\Programs\Android Studio\jbr\bin\keytool.exe",
    "${env:ProgramFiles(x86)}\Android\Android Studio\jbr\bin\keytool.exe"
  )
  foreach ($c in $candidates) { if ($c -and (Test-Path $c)) { return $c } }
  $onPath = Get-Command keytool -ErrorAction SilentlyContinue
  if ($onPath) { return $onPath.Source }
  $java = (flutter doctor -v 2>$null | Select-String 'Java binary at:\s*(.+)$').Matches | Select-Object -First 1
  if ($java) {
    $k = Join-Path (Split-Path $java.Groups[1].Value.Trim()) 'keytool.exe'
    if (Test-Path $k) { return $k }
  }
  throw 'keytool not found. Install Android Studio (it includes Java) or set JAVA_HOME, then run again.'
}
$keytool = Find-Keytool
Write-Host "Using $keytool"
$secure = Read-Host 'Choose a key password (at least 8 characters)' -AsSecureString
$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
if ($password.Length -lt 8) { throw 'Password too short.' }

& $keytool -genkeypair -v -keystore $jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 `
  -alias upload -storepass $password -keypass $password -dname 'CN=Daira, O=Daira, C=EG'
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $jks)) { throw 'keytool could not create the key.' }
@"
storeFile=$($jks -replace '\\','/')
storePassword=$password
keyAlias=upload
keyPassword=$password
"@ | Set-Content -Encoding ASCII 'android/key.properties'
Write-Host "Key created: $jks"
Write-Host 'android/key.properties written (ignored by git). Back up the .jks file and the password now.'
