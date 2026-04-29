#!/usr/bin/env bash
#
# PomodoCat — installeur macOS.
# Build l'app puis l'installe dans /Applications (fallback ~/Applications si pas le droit).
#
# Usage : ./install-mac.sh
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="PomodoCat"
APP_SRC="$ROOT_DIR/build/$APP_NAME.app"

cd "$ROOT_DIR"

# --- Pré-requis ---------------------------------------------------------------

if ! command -v swift >/dev/null 2>&1; then
  echo "✖ Swift introuvable. Installe les Command Line Tools : xcode-select --install"
  exit 1
fi

# --- Build --------------------------------------------------------------------

echo "▶ Build de PomodoCat (release)…"
"$ROOT_DIR/build-app.sh" release

if [[ ! -d "$APP_SRC" ]]; then
  echo "✖ Build échoué : $APP_SRC introuvable."
  exit 1
fi

# --- Détermine la destination -------------------------------------------------

SYSTEM_APPS="/Applications"
USER_APPS="$HOME/Applications"

if [[ -w "$SYSTEM_APPS" ]]; then
  DEST_DIR="$SYSTEM_APPS"
else
  echo "ℹ /Applications n'est pas accessible en écriture, installation dans ~/Applications."
  mkdir -p "$USER_APPS"
  DEST_DIR="$USER_APPS"
fi

DEST_APP="$DEST_DIR/$APP_NAME.app"

# --- Install ------------------------------------------------------------------

if [[ -d "$DEST_APP" ]]; then
  echo "▶ Suppression de l'ancienne version…"
  rm -rf "$DEST_APP"
fi

echo "▶ Copie vers $DEST_APP…"
cp -R "$APP_SRC" "$DEST_APP"

# Re-signature ad-hoc pour que Gatekeeper laisse l'app se lancer.
codesign --force --deep --sign - "$DEST_APP" >/dev/null 2>&1 || true

# --- Fin ----------------------------------------------------------------------

echo ""
echo "✔ $APP_NAME installé dans : $DEST_APP"
echo ""
echo "Lancement :"
echo "  open '$DEST_APP'"
echo ""
echo "Ou cherche '$APP_NAME' dans Spotlight (⌘ + Espace)."
echo ""
read -r -p "Lancer maintenant ? [O/n] " answer
case "${answer:-O}" in
  [Oo]*|"") open "$DEST_APP" ;;
  *) ;;
esac
