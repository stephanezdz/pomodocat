#!/usr/bin/env bash
#
# convert-cats.sh — convertit les vidéos HEVC+alpha (.mov) en WebM/VP9+alpha (.webm)
# pour que la transparence fonctionne dans la WebView Windows (WebView2 / Chromium).
#
# Mac garde les .mov originaux ; Windows utilise les .webm produits ici.
# L'app affiche les deux formats (priorité au .webm si présent côté Win).
#
# Usage:
#   ./convert-cats.sh             # convertit tout le dossier ~/.../PomodoCat/cats
#   ./convert-cats.sh fichier.mov # convertit un fichier précis
#

set -euo pipefail

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "✖ ffmpeg manquant. brew install ffmpeg" >&2
  exit 1
fi

# Dossier des chats utilisateur
case "$(uname -s)" in
  Darwin) CATS_DIR="$HOME/Library/Application Support/PomodoCat/cats" ;;
  Linux)  CATS_DIR="$HOME/.config/PomodoCat/cats" ;;
  *)      CATS_DIR="$HOME/PomodoCat/cats" ;;
esac

mkdir -p "$CATS_DIR"

convert_one() {
  local src="$1"
  local base="${src##*/}"
  local stem="${base%.*}"
  local out="$CATS_DIR/${stem}.webm"

  if [[ -f "$out" && "$out" -nt "$src" ]]; then
    echo "↺ ${base} → déjà à jour, skip"
    return 0
  fi

  echo "▶ ${base} → ${stem}.webm"
  # VP9 avec canal alpha. yuva420p = 4:2:0 + alpha, libvpx-vp9 + auto-alt-ref 0 (requis pour alpha).
  ffmpeg -y -i "$src" \
    -c:v libvpx-vp9 -pix_fmt yuva420p \
    -auto-alt-ref 0 -lag-in-frames 0 \
    -b:v 0 -crf 30 \
    -row-mt 1 -threads 0 \
    -an \
    "$out" 2>&1 | tail -5
  echo "  ✔ $out ($(du -h "$out" | cut -f1))"
}

if [[ $# -ge 1 ]]; then
  convert_one "$1"
else
  shopt -s nullglob
  found=0
  for f in "$CATS_DIR"/*.mov "$CATS_DIR"/*.mp4; do
    convert_one "$f"
    found=$((found + 1))
  done
  if [[ $found -eq 0 ]]; then
    echo "Aucun .mov / .mp4 trouvé dans $CATS_DIR"
    exit 1
  fi
fi

echo ""
echo "✔ Conversion terminée. Sortie : $CATS_DIR"
