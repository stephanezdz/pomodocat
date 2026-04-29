# install-windows.ps1 — installeur PomodoCat pour testeur sans toolchain.
#
# Lance via le .bat associe (ou directement en PowerShell si tu connais).
# Le script :
#   1. Telecharge le .exe d'installation depuis la derniere GitHub Release
#   2. Telecharge les videos .webm dans %APPDATA%\PomodoCat\cats\
#   3. Lance l'installeur
#
# Pre-requis : Windows 10/11. WebView2 deja inclus par defaut.

$ErrorActionPreference = "Stop"
$Repo = "stephanezdz/pomodocat"
$AppName = "PomodoCat"
$CatsDir = Join-Path $env:APPDATA "$AppName\cats"
$WorkDir = Join-Path $env:TEMP "pomodocat-install-$([guid]::NewGuid().ToString('N').Substring(0,8))"
New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
New-Item -ItemType Directory -Path $CatsDir  -Force | Out-Null

Write-Host ""
Write-Host "Recherche de la derniere version sur GitHub..." -ForegroundColor Cyan

# Recupere les metadonnees de la derniere release.
try {
  $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" `
                               -Headers @{ "User-Agent" = "PomodoCat-Installer" }
} catch {
  Write-Host "[X] Impossible de joindre l'API GitHub. Verifie ta connexion." -ForegroundColor Red
  exit 1
}

Write-Host "Version : $($release.tag_name)"

# Cherche le .exe (NSIS) en priorite, sinon le .msi.
$installerAsset = $release.assets |
  Where-Object { $_.name -match '\.(exe|msi)$' -and $_.name -match 'x64' } |
  Sort-Object { if ($_.name -match '\.exe$') { 0 } else { 1 } } |
  Select-Object -First 1

if (-not $installerAsset) {
  Write-Host "[X] Aucun installeur Windows trouve dans cette release." -ForegroundColor Red
  exit 1
}

$installerPath = Join-Path $WorkDir $installerAsset.name
Write-Host ""
Write-Host "Telechargement de l'installeur..." -ForegroundColor Cyan
Write-Host "  $($installerAsset.name) ($([math]::Round($installerAsset.size / 1MB, 1)) Mo)"

Invoke-WebRequest -Uri $installerAsset.browser_download_url `
                  -OutFile $installerPath `
                  -UseBasicParsing

# Telecharge les chats .webm (Windows ne lit pas le HEVC alpha des .mov).
Write-Host ""
Write-Host "Telechargement des chats (.webm)..." -ForegroundColor Cyan
$catAssets = $release.assets | Where-Object { $_.name -match '\.webm$' }

if ($catAssets.Count -eq 0) {
  Write-Host "  (aucun chat dans la release - l'app utilisera l'emoji par defaut)" -ForegroundColor Yellow
} else {
  foreach ($asset in $catAssets) {
    $dest = Join-Path $CatsDir $asset.name
    if (Test-Path $dest) {
      Write-Host "  $($asset.name) (deja present, skip)"
    } else {
      Write-Host "  $($asset.name) ($([math]::Round($asset.size / 1MB, 1)) Mo)"
      Invoke-WebRequest -Uri $asset.browser_download_url `
                        -OutFile $dest `
                        -UseBasicParsing
    }
  }
}

# Lance l'installeur.
Write-Host ""
Write-Host "Lancement de l'installeur..." -ForegroundColor Cyan
Write-Host "  Si SmartScreen affiche un avertissement (app non signee Microsoft),"
Write-Host "  clique 'Informations complementaires' puis 'Executer quand meme'."
Write-Host ""
Start-Process -FilePath $installerPath -Wait

# Cleanup.
Remove-Item -Recurse -Force $WorkDir -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "[OK] PomodoCat est installe." -ForegroundColor Green
Write-Host "     Chats dans : $CatsDir"
Write-Host ""
Write-Host "L'icone PomodoCat apparait dans la zone de notification (en bas a droite)."
Write-Host "Clic gauche : ouvre la fenetre. Clic droit : menu."
Write-Host ""
