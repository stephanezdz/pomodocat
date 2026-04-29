# PomodoCat — guide pour Claude

> Brief pour toute session Claude Code reprenant ce repo. Lis ça d'abord.

## Le concept

Pomodoro timer (25/5/15) avec un **chat plein écran transparent** qui apparaît au-dessus de tout le bureau à la fin d'une session focus. Comportement Pomodoro classique + sélecteur de chats + réglages des durées.

## Deux versions coexistent

### `tauri/` — la version cross-plateforme (active)

Tauri 2 + Rust + TypeScript. **C'est celle qu'on développe.** Build Mac (.dmg) **et** Windows (.msi) depuis le même code.

- Backend Rust : [`tauri/src-tauri/src/lib.rs`](tauri/src-tauri/src/lib.rs)
- Frontend TS : [`tauri/src/`](tauri/src/) (`main.ts`, `store.ts`, `views.ts`, `overlay.ts`)
- Config Tauri : [`tauri/src-tauri/tauri.conf.json`](tauri/src-tauri/tauri.conf.json)
- Doc : [`tauri/README.md`](tauri/README.md)

### `Sources/` — la version SwiftUI (référence, gelée)

Premier proto Mac uniquement, fait en SwiftUI. Conservée pour comparaison visuelle / continuité. **Ne plus modifier.** Si tu dois faire évoluer l'app, c'est dans `tauri/`.

## L'overlay du chat — point sensible

C'est la fonctionnalité la plus délicate. Elle utilise **une deuxième fenêtre Tauri** transparente plein écran (pas un `<div>` dans la fenêtre principale) :

- `transparent: true` + `decorations: false` + `always_on_top: true`
- Sur macOS, `NSWindow.level` est forcé à `1000` (NSScreenSaverWindowLevel) via le crate `cocoa` pour passer **au-dessus du menu bar et du Dock**.
- Requiert le feature `macos-private-api` dans `tauri/src-tauri/Cargo.toml` ET `app.macOSPrivateApi: true` dans `tauri.conf.json`.
- Code Rust : `show_cat_overlay()` dans `lib.rs`. Frontend dédié : `tauri/overlay.html` + `tauri/src/overlay.ts`.

## Vidéos de chats — formats par plateforme

C'est l'autre point chaud à connaître :

| Plateforme | WebView | Format alpha qui marche |
|---|---|---|
| macOS  | WKWebView | **HEVC alpha** dans `<video>` ✅ |
| Windows | WebView2  | **WebM/VP9 alpha** dans `<video>` ✅ |

Les `.mov` HEVC fournis par l'utilisateur **ne marcheront pas** sur Windows. Il faut les convertir avec `tauri/scripts/convert-cats.sh` (utilise ffmpeg, syntaxe `libvpx-vp9 -pix_fmt yuva420p`).

L'app stocke les chats dans :
- macOS  : `~/Library/Application Support/PomodoCat/cats/`
- Windows : `%APPDATA%\PomodoCat\cats\`
- Linux  : `~/.config/PomodoCat/cats/`

(Pas dans le bundle. Pas de rebuild pour ajouter un chat.)

## Comment builder

```bash
cd tauri
npm install            # 1ère fois
npx tauri dev          # dev avec hot-reload
npx tauri build        # release : .app + .dmg sur Mac, .msi + .exe sur Windows
npx tauri build --no-bundle  # juste le binaire
```

**Cross-compilation Mac → Windows : ne marche pas.** Le build Windows doit se faire sur Windows (machine réelle, VM ou GitHub Actions). Voir `.github/workflows/release.yml`.

## État actuel

- ✅ Splash, sidebar, vue Timer, vue Réglages (théorie + sliders + toggles + picker)
- ✅ Préférences persistées via localStorage
- ✅ Sélection chat persistée
- ✅ Scan auto du dossier user
- ✅ Overlay full-screen au-dessus de tout (vraie fenêtre Tauri transparente)
- ✅ Bouton X bas-centre + Esc, pas de clic-vidéo-pour-fermer
- ✅ DMG produit pour aarch64 (Apple Silicon)
- ⏳ MSI Windows : pas encore testé sur une vraie machine Windows
- ⏳ GitHub Actions configuré mais pas encore tagué
- ⏳ Icône : placeholder dégradé, pas encore d'icon set définitif

## Si l'utilisateur dit "build Windows"

1. Vérifie qu'on est bien sur Windows (`uname` ou `OS` env var).
2. Vérifie le toolchain : `rustc`, `cargo`, `node`, `npm`, MSVC (test : `cargo build` doit marcher).
3. WebView2 runtime (généralement déjà sur Win10/11).
4. `cd tauri && npm install && npx tauri build`
5. MSI dans `tauri/src-tauri/target/release/bundle/msi/`.
6. Pour les chats : lance `tauri/scripts/convert-cats.sh` (Bash) ou la version PowerShell équivalente pour générer les `.webm`.

## Si l'utilisateur dit "ajoute X"

- Réglage durée → `tauri/src/types.ts` (DEFAULT_PREFS, PREF_RANGES) + `tauri/src/views.ts` (renderSettingsView)
- Nouvelle vue dans la sidebar → `SidebarItem` dans `tauri/src/views.ts`
- Permission Tauri → `tauri/src-tauri/capabilities/default.json`
- Commande Rust → `tauri/src-tauri/src/lib.rs` + `invoke_handler!`
