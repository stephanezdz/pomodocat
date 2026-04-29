# PomodoCat — version Tauri (Mac + Windows)

Port cross-plateforme de PomodoCat. Un seul codebase, deux binaires natifs.

## Stack

- **Backend natif** : Rust + Tauri 2 (~4 Mo de binaire sur Mac)
- **Frontend** : TypeScript + Vite (vanilla, pas de framework)
- **Vidéo transparente** :
  - macOS → WKWebView lit le **HEVC alpha** (`.mov`) directement dans `<video>` ✅
  - Windows → WebView2 lit le **WebM/VP9 alpha** (`.webm`) — il faut convertir les `.mov` (script fourni)

## Lancement local (dev)

```bash
cd tauri
npm install         # 1ère fois
npx tauri dev       # ouvre l'app avec hot-reload
```

## Build natif (sans installer)

```bash
npx tauri build              # Mac : .app + .dmg, Win : .msi + .exe
npx tauri build --no-bundle  # juste le binaire, plus rapide
```

## Installation

| Plateforme | Commande |
|---|---|
| macOS  | `./install-mac.sh`                  → produit + installe `.app` dans `/Applications` |
| Windows | `.\install-windows.ps1` (PowerShell) → produit + signale le `.msi` |

## Vidéos de chats

L'app scanne :

- macOS  : `~/Library/Application Support/PomodoCat/cats/`
- Windows: `%APPDATA%\PomodoCat\cats\`
- Linux  : `~/.config/PomodoCat/cats/`

**Formats acceptés** : `.mov`, `.mp4`, `.webm`, `.gif`, `.png` (animé).

### Conversion HEVC alpha → WebM alpha (pour Windows)

```bash
./scripts/convert-cats.sh                 # tout le dossier
./scripts/convert-cats.sh fichier.mov     # un fichier
```

Le script utilise `ffmpeg` (installable via `brew install ffmpeg` sur Mac, `winget install ffmpeg` sur Windows). Il produit un `.webm` à côté du `.mov`. L'app affiche les deux : sur Mac le `.mov` HEVC marche directement, sur Windows il faut le `.webm`.

## Structure

```
tauri/
├── index.html               UI shell HTML
├── src/                     Frontend TypeScript
│   ├── main.ts              point d'entrée + routing
│   ├── store.ts             stores (Prefs, Cat, Timer)
│   ├── views.ts             rendu des vues (sidebar, timer, settings, overlay)
│   ├── types.ts             types partagés
│   └── style.css            thème CleanMyMac-like
├── src-tauri/               Backend Rust + config Tauri
│   ├── Cargo.toml
│   ├── tauri.conf.json      config (fenêtre, sécurité, bundle)
│   ├── capabilities/        permissions Tauri
│   └── src/
│       ├── main.rs
│       └── lib.rs           commandes IPC : list_cats, get_cats_dir
├── scripts/
│   └── convert-cats.sh      HEVC → WebM
├── install-mac.sh
├── install-windows.ps1
└── package.json
```

## État du portage

| Feature | État |
|---|---|
| Splash (tomate + chat) | ✅ |
| Sidebar (Timer / Sessions / Stats / Réglages) | ✅ |
| Vue Timer (chrono circulaire, controls, pills) | ✅ |
| Réglages (théorie, durées sliders + reset, toggles, picker) | ✅ |
| Persistance préférences (localStorage) | ✅ |
| Sélection chat persistée | ✅ |
| Scan automatique du dossier user | ✅ |
| Vidéo transparente fond bureau (overlay) | ⚠️ pour l'instant l'overlay est dans la fenêtre principale ; la version "vraie" full-screen au-dessus du bureau demande une fenêtre Tauri séparée transparente — prévu pour la session suivante |
| Bouton X bas-centre, Esc, pas de clic-vidéo-pour-fermer | ✅ |
| Son configurable | ✅ |
| Auto-start phase suivante | ✅ |
| Installeurs Mac / Windows | ✅ scripts |

## Limites connues

1. **Overlay full-screen** : la version actuelle pose l'overlay dans la fenêtre principale. Pour qu'il apparaisse vraiment par-dessus le bureau (comme la version SwiftUI), il faut créer une seconde fenêtre Tauri `transparent: true, decorations: false, alwaysOnTop: true`. C'est ~30 lignes de Rust + 1 fichier HTML overlay dédié — pas dans cette session.
2. **Format vidéo** : tes `.mov` HEVC marcheront sur Mac, pas sur Windows. Lance `./scripts/convert-cats.sh` après avoir ajouté de nouveaux chats si tu veux que Windows les voit.
3. **Icône** : un placeholder dégradé est fourni. Pour le release, génère un vrai icon set avec [tauri icon](https://tauri.app/distribute/) à partir d'une image source 1024×1024.
