#!/usr/bin/env bash
#
# install-mac.command — installeur PomodoCat pour testeur sans toolchain.
#
# Double-clic dans le Finder. Le script :
#   1. Télécharge le DMG depuis la dernière GitHub Release
#   2. Télécharge les vidéos de chats
#   3. Installe l'app dans /Applications (avec contournement Gatekeeper)
#   4. Pose les chats dans ~/Library/Application Support/PomodoCat/cats/
#   5. Lance l'app
#
# Aucun pré-requis : juste macOS 13+ (Apple Silicon ou Intel).

set -euo pipefail

REPO="stephanezdz/pomodocat"
APP_NAME="PomodoCat"
CATS_DIR="$HOME/Library/Application Support/PomodoCat/cats"
WORK_DIR="$(mktemp -d -t pomodocat-install)"

echo ""
echo "🐱  Installation de $APP_NAME"
echo "──────────────────────────────"
echo ""

# Détecte l'archi : Apple Silicon (aarch64) ou Intel (x64).
ARCH="$(uname -m)"
if [[ "$ARCH" == "arm64" ]]; then
  DMG_PATTERN="*aarch64.dmg"
  ARCH_LABEL="Apple Silicon"
else
  DMG_PATTERN="*x64.dmg"
  ARCH_LABEL="Intel"
fi
echo "Mac détecté : $ARCH_LABEL"

# Récupère l'URL de la dernière release.
echo "Recherche de la dernière version sur GitHub…"
LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')

if [[ -z "$LATEST_TAG" ]]; then
  echo "✖ Impossible de trouver une release publiée. (Le repo n'a peut-être que des drafts.)"
  echo "  Va sur https://github.com/$REPO/releases et publie le draft."
  exit 1
fi
echo "Version : $LATEST_TAG"

# Liste les assets et trouve le DMG correspondant.
ASSET_URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep -E '"browser_download_url".*\.dmg' \
  | grep -i "$(echo "$DMG_PATTERN" | sed 's/\*//')" \
  | head -1 \
  | sed -E 's/.*"browser_download_url": *"([^"]+)".*/\1/')

if [[ -z "$ASSET_URL" ]]; then
  echo "✖ Pas de DMG $ARCH_LABEL trouvé dans la release $LATEST_TAG."
  exit 1
fi

echo ""
echo "▶ Téléchargement de l'app…"
DMG_PATH="$WORK_DIR/PomodoCat.dmg"
curl -fL --progress-bar "$ASSET_URL" -o "$DMG_PATH"

# Téléchargement des chats (assets .webm joints à la release).
echo ""
echo "▶ Téléchargement des chats…"
mkdir -p "$CATS_DIR"
WEBM_URLS=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep -E '"browser_download_url".*\.webm' \
  | sed -E 's/.*"browser_download_url": *"([^"]+)".*/\1/' || true)
MOV_URLS=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep -E '"browser_download_url".*\.mov' \
  | sed -E 's/.*"browser_download_url": *"([^"]+)".*/\1/' || true)

# Sur Mac, on prend les .mov (HEVC alpha = 4K). Si pas dispos, fallback .webm.
if [[ -n "$MOV_URLS" ]]; then
  CAT_URLS="$MOV_URLS"
else
  CAT_URLS="$WEBM_URLS"
fi

if [[ -n "$CAT_URLS" ]]; then
  while IFS= read -r url; do
    [[ -z "$url" ]] && continue
    fname="$(basename "$url")"
    if [[ -f "$CATS_DIR/$fname" ]]; then
      echo "  ↺ $fname (déjà présent, skip)"
    else
      echo "  ▶ $fname"
      curl -fL --progress-bar "$url" -o "$CATS_DIR/$fname"
    fi
  done <<< "$CAT_URLS"
else
  echo "  (aucun chat dans la release — l'app utilisera l'emoji par défaut)"
fi

# Mount + copie de l'app + démontage.
echo ""
echo "▶ Installation dans /Applications…"
xattr -cr "$DMG_PATH" 2>/dev/null || true

MOUNT_OUTPUT=$(hdiutil attach -nobrowse -readonly "$DMG_PATH")
MOUNT_POINT=$(echo "$MOUNT_OUTPUT" | grep -E "Volumes/$APP_NAME" | tail -1 | awk '{ print $NF }')

if [[ ! -d "$MOUNT_POINT/$APP_NAME.app" ]]; then
  echo "✖ Le DMG ne contient pas $APP_NAME.app"
  hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
  exit 1
fi

# Choix /Applications vs ~/Applications selon les droits.
if [[ -w "/Applications" ]]; then
  DEST_DIR="/Applications"
else
  DEST_DIR="$HOME/Applications"
  mkdir -p "$DEST_DIR"
fi
DEST_APP="$DEST_DIR/$APP_NAME.app"

[[ -d "$DEST_APP" ]] && rm -rf "$DEST_APP"
cp -R "$MOUNT_POINT/$APP_NAME.app" "$DEST_APP"
hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true

# Contournement Gatekeeper (l'app n'est pas signée par Apple Developer ID).
xattr -cr "$DEST_APP" 2>/dev/null || true
codesign --force --deep --sign - "$DEST_APP" >/dev/null 2>&1 || true

# Cleanup.
rm -rf "$WORK_DIR"

echo ""
echo "✔ $APP_NAME installé dans : $DEST_APP"
echo "✔ Chats dans : $CATS_DIR"
echo ""

# Lance l'app.
open "$DEST_APP"

echo "🐱 PomodoCat est lancé. L'icône est dans la barre de menu en haut à droite."
echo ""
read -r -p "Appuie sur Entrée pour fermer cette fenêtre…" _
