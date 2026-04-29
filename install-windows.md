# PomodoCat — installation Windows

## ⚠️ Statut actuel : pas de version Windows

PomodoCat est aujourd'hui développé en **SwiftUI**, le framework natif d'Apple. **SwiftUI ne fonctionne pas sur Windows.** Il n'existe donc pas (encore) de binaire `.exe` à installer.

Le proto Mac valide le concept (UI, sélection de chats, vidéo transparente, durées paramétrables). L'étape Windows demande de **réécrire l'app** dans une techno multi-plateforme. Tant que cette réécriture n'a pas eu lieu, ce fichier sert de note honnête plutôt que d'installeur.

---

## Trois options pour livrer Windows

### Option A — Tauri (Rust + Web) — recommandé

[Tauri](https://tauri.app/) produit des binaires natifs Mac, Windows et Linux à partir d'un seul code (Rust côté backend, HTML/CSS/JS ou un framework web côté UI). On reproduit le look CleanMyMac en CSS, on bundle le tout, et on a un `.msi` Windows + un `.dmg` Mac depuis le même repo.

| Critère | Détail |
|---|---|
| Codebase | unique (Rust + frontend web) |
| Taille du binaire | ~10–20 Mo |
| Performances | natives (WebView2 sur Windows, WKWebView sur Mac) |
| Effort de portage | ~3–5 jours pour reproduire le proto actuel |
| Vidéo transparente | supporté via `<video>` HTML + WebM/VP9 alpha (différent de HEVC) |

**Recommandation forte si Windows est important pour toi.**

### Option B — .NET MAUI (C# + XAML)

[.NET MAUI](https://learn.microsoft.com/dotnet/maui/) cible Windows, Mac, iOS et Android. C# côté logique, XAML côté UI.

| Critère | Détail |
|---|---|
| Codebase | unique (C#) |
| Taille du binaire | ~80–150 Mo (runtime .NET inclus) |
| Performances | natives |
| Effort de portage | ~5–7 jours |
| Vidéo transparente | supporté via `MediaElement` ou `WebView` |

Bon choix si tu veux pousser sur Microsoft Store par la suite.

### Option C — Electron

[Electron](https://www.electronjs.org/) embarque Chromium + Node.js dans un binaire desktop.

| Critère | Détail |
|---|---|
| Codebase | unique (web) |
| Taille du binaire | ~150–200 Mo |
| Performances | RAM élevée, CPU correct |
| Effort de portage | ~3–4 jours |
| Vidéo transparente | identique à Tauri |

Solution éprouvée mais lourde — Tauri donne le même résultat avec un dixième du poids.

---

## Décision à prendre

Quand tu valides le proto Mac, dis-moi laquelle des trois options tu préfères et on lance le port. **Mon avis : Tauri**, parce que :

- on garde le rendu fidèle de l'UI actuelle (CSS reproduit le look CleanMyMac à l'identique)
- l'installeur Windows fait moins de 20 Mo
- Rust côté logique = robuste et léger
- maintenance simple : un seul codebase pour Mac et Windows

---

## En attendant

Si quelqu'un sous Windows veut tester PomodoCat tout de suite, la seule option est de :

1. utiliser un Mac (macOS 13+)
2. ou une VM macOS (peu pratique, performances vidéo dégradées)
3. ou attendre le port Windows

Pour Mac : voir `install-mac.sh`.
