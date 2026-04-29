#!/usr/bin/env bash
#
# install-mac.sh — build PomodoCat (Tauri) et l'installe en .app dans /Applications.
#
# Pré-requis : Rust (rustup), Node.js (≥18). Si manquants, installe-les d'abord :
#   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
#   brew install node
#
# Usage : ./install-mac.sh
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="PomodoCat"

cd "$ROOT_DIR"

# --- Pré-requis -------------------------------------------------------------

if ! command -v cargo >/dev/null 2>&1; then
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck disable=SC1091
    . "$HOME/.cargo/env"
  fi
fi

for cmd in node npm cargo; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "✖ $cmd introuvable. Installe-le puis relance." >&2
    [[ "$cmd" == "cargo" ]] && echo "  → curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y" >&2
    [[ "$cmd" == "node" || "$cmd" == "npm" ]] && echo "  → brew install node" >&2
    exit 1
  fi
done

# --- Install npm deps -------------------------------------------------------

if [[ ! -d node_modules ]]; then
  echo "▶ Installation des dépendances npm…"
  npm install
fi

# --- Build .app + DMG -------------------------------------------------------

echo "▶ Build de PomodoCat (Tauri release, 2-5 min)…"
npx tauri build

APP_SRC="$ROOT_DIR/src-tauri/target/release/bundle/macos/$APP_NAME.app"
DMG_SRC=$(find "$ROOT_DIR/src-tauri/target/release/bundle/dmg" -name "*.dmg" 2>/dev/null | head -1 || true)

if [[ ! -d "$APP_SRC" ]]; then
  echo "✖ Build introuvable : $APP_SRC" >&2
  exit 1
fi

# --- Install ----------------------------------------------------------------

SYSTEM_APPS="/Applications"
USER_APPS="$HOME/Applications"

if [[ -w "$SYSTEM_APPS" ]]; then
  DEST_DIR="$SYSTEM_APPS"
else
  echo "ℹ /Applications non accessible en écriture, installation dans ~/Applications."
  mkdir -p "$USER_APPS"
  DEST_DIR="$USER_APPS"
fi

DEST_APP="$DEST_DIR/$APP_NAME.app"

[[ -d "$DEST_APP" ]] && rm -rf "$DEST_APP"
cp -R "$APP_SRC" "$DEST_APP"

# Re-signature ad-hoc pour Gatekeeper local.
codesign --force --deep --sign - "$DEST_APP" >/dev/null 2>&1 || true

echo ""
echo "✔ PomodoCat installé : $DEST_APP"
[[ -n "${DMG_SRC:-}" ]] && echo "  DMG distribuable : $DMG_SRC"
echo ""

read -r -p "Lancer maintenant ? [O/n] " answer
case "${answer:-O}" in
  [Oo]*|"") open "$DEST_APP" ;;
  *) ;;
esac
