# install-windows.ps1 — build PomodoCat (Tauri) et installe le MSI.
#
# Pré-requis :
#   - Rust : https://rustup.rs/  (installer .exe, redémarrer le terminal après)
#   - Node.js LTS : https://nodejs.org/  (≥ 18)
#   - Microsoft Visual Studio Build Tools (workload "Desktop development with C++")
#   - WebView2 runtime (généralement déjà installé sur Windows 11 ; sinon
#     https://developer.microsoft.com/microsoft-edge/webview2/)
#
# Lancement : clic droit > "Run with PowerShell"
#   ou depuis un PowerShell dans ce dossier :
#     Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#     .\install-windows.ps1
#

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

function Need($name, $hint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Host "[X] $name introuvable." -ForegroundColor Red
    Write-Host "    -> $hint" -ForegroundColor Yellow
    exit 1
  }
}

Write-Host ">>> Vérification du toolchain..." -ForegroundColor Cyan
Need "node"  "Installe Node.js LTS depuis https://nodejs.org/"
Need "npm"   "(fourni avec Node.js)"
Need "cargo" "Installe Rust depuis https://rustup.rs/"

if (-not (Test-Path "node_modules")) {
  Write-Host ">>> Installation des dépendances npm..." -ForegroundColor Cyan
  npm install
}

Write-Host ">>> Convert HEVC alpha videos to WebM/VP9 alpha (pour la WebView Windows)..." -ForegroundColor Cyan
$catsDir = Join-Path $env:APPDATA "PomodoCat\cats"
if (-not (Test-Path $catsDir)) {
  New-Item -ItemType Directory -Path $catsDir | Out-Null
}

if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
  Get-ChildItem -Path $catsDir -Filter "*.mov" | ForEach-Object {
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $out = Join-Path $catsDir "$stem.webm"
    if ((-not (Test-Path $out)) -or ($_.LastWriteTime -gt (Get-Item $out).LastWriteTime)) {
      Write-Host "  -> $($_.Name) -> $stem.webm"
      ffmpeg -y -i $_.FullName `
        -c:v libvpx-vp9 -pix_fmt yuva420p `
        -auto-alt-ref 0 -lag-in-frames 0 `
        -b:v 0 -crf 30 -row-mt 1 -threads 0 -an `
        $out 2>&1 | Out-Null
    }
  }
} else {
  Write-Host "[!] ffmpeg pas trouvé — la transparence ne marchera pas pour les .mov." -ForegroundColor Yellow
  Write-Host "    Installe ffmpeg : winget install ffmpeg" -ForegroundColor Yellow
}

Write-Host ">>> Build de PomodoCat (Tauri release, 3-8 min la première fois)..." -ForegroundColor Cyan
npx tauri build

# --- Localisation du .msi ---------------------------------------------------

$bundleDir = "src-tauri\target\release\bundle"
$msi = Get-ChildItem -Path "$bundleDir\msi" -Filter "*.msi" -ErrorAction SilentlyContinue | Select-Object -First 1
$exe = Get-ChildItem -Path "$bundleDir\nsis" -Filter "*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

Write-Host ""
Write-Host "[V] Build terminé." -ForegroundColor Green
if ($msi) {
  Write-Host "    Installeur MSI : $($msi.FullName)"
  Write-Host ""
  Write-Host "Lance-le pour installer (ou copie sur une autre machine Windows)."
} elseif ($exe) {
  Write-Host "    Installeur EXE : $($exe.FullName)"
} else {
  Write-Host "    Binaire brut   : src-tauri\target\release\pomodocat.exe"
}
