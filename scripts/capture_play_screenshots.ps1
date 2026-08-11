# Play Store screenshot otomasyonu (1080x1920)
param(
  [string]$Serial = "emulator-5558",
  [string]$OutDir = "play_store_assets/screenshots"
)

$ErrorActionPreference = "Stop"
$adbExe = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adbExe)) { throw "adb yok: $adbExe" }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$pkg = "com.kelimebahis.kelime_bahis"
$adbArgs = @("-s", $Serial)

function Capture([string]$name) {
  $remote = "/sdcard/kb_$name.png"
  $local = Join-Path $OutDir "$name.png"
  & $adbExe @adbArgs shell screencap -p $remote
  & $adbExe @adbArgs pull $remote $local | Out-Null
  & $adbExe @adbArgs shell rm $remote
  Write-Host "OK $name -> $local"
}

Write-Host "Cihaz: $Serial"
& $adbExe @adbArgs shell wm size
& $adbExe @adbArgs shell am force-stop $pkg
Start-Sleep -Seconds 1
& $adbExe @adbArgs shell monkey -p $pkg -c android.intent.category.LAUNCHER 1
Start-Sleep -Seconds 5

Capture "01_home"

& $adbExe @adbArgs shell input tap 540 1550
Start-Sleep -Seconds 2
Capture "02_playing"

& $adbExe @adbArgs shell input keyevent 4
Start-Sleep -Seconds 1

& $adbExe @adbArgs shell input swipe 540 320 540 320 1400
Start-Sleep -Seconds 2
# Mağaza (L1) bounds y≈1122–1269
& $adbExe @adbArgs shell input tap 540 1195
Start-Sleep -Seconds 2
Capture "03_shop"

& $adbExe @adbArgs shell input keyevent 4
Start-Sleep -Seconds 1
& $adbExe @adbArgs shell input swipe 540 320 540 320 1400
Start-Sleep -Seconds 2
# Boss playing y≈1416–1563
& $adbExe @adbArgs shell input tap 540 1490
Start-Sleep -Seconds 2
Capture "04_boss_playing"

& $adbExe @adbArgs shell input keyevent 4
Start-Sleep -Seconds 1
& $adbExe @adbArgs shell input swipe 540 320 540 320 1400
Start-Sleep -Seconds 2
# Kazandı y≈1563–1710
& $adbExe @adbArgs shell input tap 540 1636
Start-Sleep -Seconds 2
Capture "05_won"

& $adbExe @adbArgs shell input keyevent 4
Start-Sleep -Seconds 1
& $adbExe @adbArgs shell input swipe 540 320 540 320 1400
Start-Sleep -Seconds 2
# Kaybetti y≈1710–1857
& $adbExe @adbArgs shell input tap 540 1783
Start-Sleep -Seconds 2
Capture "06_lost"

Write-Host "Bitti."
Get-ChildItem $OutDir -Filter "*.png" | Format-Table Name, Length
