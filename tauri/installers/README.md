# PomodoCat — Installeurs pour testeurs

Ces deux scripts permettent à n'importe qui de tester PomodoCat **sans installer aucun toolchain de dev**. Ils téléchargent l'app + les chats depuis la dernière GitHub Release publiée, puis installent.

## macOS

1. Télécharge **`install-mac.zip`** sur ton Mac. *(Pas le `.command` direct — GitHub strip le bit exécutable au download. Le zip le préserve.)*
2. Safari / Chrome décompresse automatiquement → tu obtiens `install-mac.command` dans `Downloads/`.
3. Double-clic dessus dans le Finder. *(Si Gatekeeper refuse au premier essai, clic-droit → Ouvrir → Ouvrir dans la dialog.)*
4. Le terminal s'ouvre, le script tourne 30s à 1 min.
5. PomodoCat se lance automatiquement à la fin.

**Si même le double-clic refuse** (macOS Sequoia est strict), ouvre Terminal et lance :
```bash
bash ~/Downloads/install-mac.command
```

L'icône apparaît dans la **barre de menu** (en haut à droite). Clic gauche pour afficher la fenêtre, clic droit pour le menu.

## Windows

1. Télécharge **`install-windows.bat`** sur ton PC.
2. Double-clic dessus dans l'Explorateur. *(Windows SmartScreen va peut-être avertir : "Plus d'infos" → "Exécuter quand même".)*
3. PowerShell télécharge l'installeur, le lance.
4. L'installeur Tauri demande où installer (par défaut `C:\Program Files\PomodoCat`).
5. Lance PomodoCat depuis le menu Démarrer.

L'icône apparaît dans la **zone de notification** (à côté de l'horloge, en bas à droite). Clic gauche pour afficher la fenêtre, clic droit pour le menu.

## Comment ça marche

- Le script lit `https://api.github.com/repos/stephanezdz/pomodocat/releases/latest`
- Détecte l'archi (Apple Silicon / Intel / Windows x64) et choisit le bon installeur
- Télécharge les vidéos `.webm` (compatibles Windows et Mac) ou `.mov` (préférées sur Mac, HEVC alpha 4K)
- Pose les chats dans :
  - macOS  : `~/Library/Application Support/PomodoCat/cats/`
  - Windows: `%APPDATA%\PomodoCat\cats\`
- Sur Mac, contourne Gatekeeper (signature ad-hoc + suppression du flag quarantine)

## Si ça plante

- **Aucune release publiée** : va sur https://github.com/stephanezdz/pomodocat/releases et clique "Publish release" sur le dernier draft.
- **`curl: command not found`** : le Mac est trop ancien (< macOS 10.15). Utilise un Mac plus récent.
- **PowerShell bloqué** : lance `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` une fois, puis re-double-clic le `.bat`.
