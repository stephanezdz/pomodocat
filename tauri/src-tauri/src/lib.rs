use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::sync::Mutex;
use tauri::{
    menu::{Menu, MenuItem, PredefinedMenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    Emitter, Manager, WebviewUrl, WebviewWindowBuilder,
};

// ============================================================================
// Cat library
// ============================================================================

/// One asset discovered in the user's cats folder.
#[derive(Serialize, Clone)]
struct CatAsset {
    id: String,
    path: String,
    display_name: String,
    kind: String, // "video" or "image"
}

/// Returns the user-writable directory where cat videos live.
/// We deliberately use a stable "PomodoCat" folder (not the bundle id)
/// so the SwiftUI version and the Tauri version share the same folder.
fn cats_dir() -> Result<PathBuf, String> {
    #[cfg(target_os = "macos")]
    let base: PathBuf = {
        let home = std::env::var("HOME").map_err(|_| "HOME not set".to_string())?;
        PathBuf::from(home).join("Library/Application Support/PomodoCat")
    };
    #[cfg(target_os = "windows")]
    let base: PathBuf = {
        let appdata = std::env::var("APPDATA").map_err(|_| "APPDATA not set".to_string())?;
        PathBuf::from(appdata).join("PomodoCat")
    };
    #[cfg(not(any(target_os = "macos", target_os = "windows")))]
    let base: PathBuf = {
        let home = std::env::var("HOME").map_err(|_| "HOME not set".to_string())?;
        PathBuf::from(home).join(".config/PomodoCat")
    };

    let dir = base.join("cats");
    if !dir.exists() {
        std::fs::create_dir_all(&dir).map_err(|e| format!("create cats dir: {e}"))?;
    }
    Ok(dir)
}

#[tauri::command]
fn get_cats_dir() -> Result<String, String> {
    Ok(cats_dir()?.to_string_lossy().to_string())
}

#[tauri::command]
fn list_cats() -> Result<Vec<CatAsset>, String> {
    let dir = cats_dir()?;
    let mut cats: Vec<CatAsset> = Vec::new();

    let video_exts = ["mov", "mp4", "webm"];
    let image_exts = ["gif", "png"];

    let entries = match std::fs::read_dir(&dir) {
        Ok(it) => it,
        Err(_) => return Ok(cats),
    };

    for entry in entries.flatten() {
        let path = entry.path();
        if !path.is_file() {
            continue;
        }
        let Some(ext) = path
            .extension()
            .and_then(|e| e.to_str())
            .map(|s| s.to_lowercase())
        else {
            continue;
        };

        let kind = if video_exts.contains(&ext.as_str()) {
            "video"
        } else if image_exts.contains(&ext.as_str()) {
            "image"
        } else {
            continue;
        };

        let id = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("unknown")
            .to_string();

        let display_name = prettify(
            path.file_stem()
                .and_then(|n| n.to_str())
                .unwrap_or("Cat"),
        );

        cats.push(CatAsset {
            id,
            path: path.to_string_lossy().to_string(),
            display_name,
            kind: kind.to_string(),
        });
    }

    cats.sort_by(|a, b| {
        a.display_name
            .to_lowercase()
            .cmp(&b.display_name.to_lowercase())
    });
    Ok(cats)
}

fn prettify(raw: &str) -> String {
    raw.replace(['_', '-'], " ")
        .split_whitespace()
        .map(|w| {
            let mut chars = w.chars();
            match chars.next() {
                Some(first) => first.to_uppercase().collect::<String>() + chars.as_str(),
                None => String::new(),
            }
        })
        .collect::<Vec<_>>()
        .join(" ")
}

// ============================================================================
// Cat overlay (separate transparent fullscreen window)
// ============================================================================

/// Cat info passed from the main window to the overlay window via shared state.
#[derive(Serialize, Deserialize, Clone, Default)]
struct OverlayCat {
    path: String,
    kind: String,
    sound_enabled: bool,
}

#[derive(Default)]
struct OverlayState {
    current: Mutex<Option<OverlayCat>>,
}

/// Spawn a fullscreen transparent overlay window with the given cat playing on top of everything.
#[tauri::command]
fn show_cat_overlay(
    app: tauri::AppHandle,
    state: tauri::State<'_, OverlayState>,
    path: String,
    kind: String,
    sound_enabled: bool,
) -> Result<(), String> {
    *state.current.lock().unwrap() = Some(OverlayCat {
        path,
        kind,
        sound_enabled,
    });

    // Tear down any existing overlay window so we can recreate fresh.
    if let Some(existing) = app.get_webview_window("cat-overlay") {
        let _ = existing.close();
    }

    let window = WebviewWindowBuilder::new(&app, "cat-overlay", WebviewUrl::App("overlay.html".into()))
        .title("PomodoCat — Cat")
        .transparent(true)
        .decorations(false)
        .resizable(false)
        .always_on_top(true)
        .skip_taskbar(true)
        .visible(false)
        .shadow(false)
        .build()
        .map_err(|e| format!("create overlay window: {e}"))?;

    // Cover the entire primary monitor (including menu bar / dock area).
    if let Ok(Some(monitor)) = window.primary_monitor() {
        let _ = window.set_position(*monitor.position());
        let _ = window.set_size(*monitor.size());
    }

    // On macOS, push the window above the menu bar by setting NSWindow.level.
    #[cfg(target_os = "macos")]
    {
        use cocoa::appkit::{NSWindow, NSWindowCollectionBehavior};
        use cocoa::base::id;

        if let Ok(ns_window_ptr) = window.ns_window() {
            let ns_window = ns_window_ptr as id;
            unsafe {
                // NSScreenSaverWindowLevel = 1000 — sits above the menu bar and dock.
                ns_window.setLevel_(1000);
                ns_window.setCollectionBehavior_(
                    NSWindowCollectionBehavior::NSWindowCollectionBehaviorCanJoinAllSpaces
                        | NSWindowCollectionBehavior::NSWindowCollectionBehaviorFullScreenAuxiliary
                        | NSWindowCollectionBehavior::NSWindowCollectionBehaviorStationary
                        | NSWindowCollectionBehavior::NSWindowCollectionBehaviorIgnoresCycle,
                );
            }
        }
    }

    window.show().map_err(|e| e.to_string())?;
    window.set_focus().map_err(|e| e.to_string())?;

    Ok(())
}

#[tauri::command]
fn get_overlay_cat(state: tauri::State<'_, OverlayState>) -> Option<OverlayCat> {
    state.current.lock().unwrap().clone()
}

#[tauri::command]
fn close_cat_overlay(app: tauri::AppHandle) -> Result<(), String> {
    if let Some(window) = app.get_webview_window("cat-overlay") {
        window.close().map_err(|e| e.to_string())?;
    }
    Ok(())
}

// ============================================================================
// App entry point
// ============================================================================

// ============================================================================
// System tray (macOS menu bar + Windows system tray)
// ============================================================================

fn build_tray(app: &tauri::AppHandle) -> tauri::Result<()> {
    // Menu items — IDs are read in `on_menu_event`.
    let show_item     = MenuItem::with_id(app, "tray:show",   "Afficher PomodoCat", true, None::<&str>)?;
    let toggle_item   = MenuItem::with_id(app, "tray:toggle", "Démarrer / Pause",   true, None::<&str>)?;
    let reset_item    = MenuItem::with_id(app, "tray:reset",  "Réinitialiser",      true, None::<&str>)?;
    let skip_item     = MenuItem::with_id(app, "tray:skip",   "Passer la phase",    true, None::<&str>)?;
    let separator     = PredefinedMenuItem::separator(app)?;
    let quit_item     = MenuItem::with_id(app, "tray:quit",   "Quitter",            true, Some("Cmd+Q"))?;

    let menu = Menu::with_items(
        app,
        &[&show_item, &separator, &toggle_item, &reset_item, &skip_item, &separator, &quit_item],
    )?;

    let tray = TrayIconBuilder::with_id("pomodocat-tray")
        .icon(app.default_window_icon().expect("no default icon").clone())
        .icon_as_template(true) // Mac menu bar adapts to dark/light
        .tooltip("PomodoCat")
        .menu(&menu)
        .show_menu_on_left_click(false)
        .on_menu_event(|app, event| {
            let id = event.id.as_ref();
            match id {
                "tray:show"   => show_main_window(app),
                "tray:quit"   => app.exit(0),
                // The other actions are forwarded to the frontend, which holds
                // the timer state.
                "tray:toggle" | "tray:reset" | "tray:skip" => {
                    let _ = app.emit("tray-action", id.trim_start_matches("tray:"));
                    show_main_window(app);
                }
                _ => {}
            }
        })
        .on_tray_icon_event(|tray, event| {
            // Left click = toggle main window visibility
            if let TrayIconEvent::Click {
                button: MouseButton::Left,
                button_state: MouseButtonState::Up,
                ..
            } = event
            {
                let app = tray.app_handle();
                if let Some(window) = app.get_webview_window("main") {
                    if window.is_visible().unwrap_or(false) && window.is_focused().unwrap_or(false) {
                        let _ = window.hide();
                    } else {
                        let _ = window.show();
                        let _ = window.unminimize();
                        let _ = window.set_focus();
                    }
                }
            }
        })
        .build(app)?;

    let _ = tray;
    Ok(())
}

fn show_main_window(app: &tauri::AppHandle) {
    if let Some(window) = app.get_webview_window("main") {
        let _ = window.show();
        let _ = window.unminimize();
        let _ = window.set_focus();
    }
}

// ============================================================================
// App entry point
// ============================================================================

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_dialog::init())
        .manage(OverlayState::default())
        .invoke_handler(tauri::generate_handler![
            get_cats_dir,
            list_cats,
            show_cat_overlay,
            get_overlay_cat,
            close_cat_overlay,
        ])
        .setup(|app| {
            build_tray(app.handle())?;
            Ok(())
        })
        // Hide the main window on close instead of quitting — keeps PomodoCat in
        // the tray ready to be re-opened. The user quits via the tray menu.
        .on_window_event(|window, event| {
            if let tauri::WindowEvent::CloseRequested { api, .. } = event {
                if window.label() == "main" {
                    let _ = window.hide();
                    api.prevent_close();
                }
            }
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
