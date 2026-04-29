import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { CatStore, PrefsStore, TimerStore } from "./store";
import {
  SidebarItem,
  renderPlaceholder,
  renderSettingsView,
  renderSidebar,
  renderTimerView,
} from "./views";

// ---------------------------------------------------------------------------
// Bootstrap
// ---------------------------------------------------------------------------

const prefs = new PrefsStore();
const cats = new CatStore();
const timer = new TimerStore(prefs);

// Trigger the dedicated fullscreen overlay window when a phase ends.
timer.phaseFinished.on(async () => {
  const current = cats.current();
  if (!current) return; // No cat to show; skip silently.
  try {
    await invoke("show_cat_overlay", {
      path: current.path,
      kind: current.kind,
      soundEnabled: prefs.get().catVideoSoundEnabled,
    });
  } catch (e) {
    console.error("show_cat_overlay failed:", e);
  }
});

const sidebarNav  = document.getElementById("sidebar-nav")  as HTMLElement;
const contentEl   = document.getElementById("content")      as HTMLElement;
const splashEl    = document.getElementById("splash")       as HTMLElement;
const appShell    = document.getElementById("app")          as HTMLElement;

let currentSection: SidebarItem = "timer";
let timerRender: ReturnType<typeof renderTimerView> | null = null;

function navigate(section: SidebarItem) {
  currentSection = section;
  renderSidebar(sidebarNav, currentSection, navigate);
  switch (section) {
    case "timer":
      timerRender = renderTimerView(contentEl, timer);
      pushPrefsToTimerView();
      pushTimerStateToView();
      break;
    case "settings":
      renderSettingsView(contentEl, prefs, cats);
      timerRender = null;
      break;
    case "sessions":
      renderPlaceholder(contentEl, "Sessions", "📚");
      timerRender = null;
      break;
    case "stats":
      renderPlaceholder(contentEl, "Statistiques", "📊");
      timerRender = null;
      break;
  }
}

function pushTimerStateToView() {
  if (!timerRender) return;
  timerRender.update(timer.get());
}

function pushPrefsToTimerView() {
  if (!timerRender) return;
  const p = prefs.get();
  timerRender.updatePillMinutes(p.focusMinutes, p.shortBreakMinutes, p.longBreakMinutes);
}

timer.changed.on(pushTimerStateToView);
prefs.changed.on(pushPrefsToTimerView);

// ---------------------------------------------------------------------------
// Splash → main app
// ---------------------------------------------------------------------------

cats.refresh().then(() => {
  navigate("timer");

  // Wait for the splash to be visible at least 1.6s.
  setTimeout(() => {
    splashEl.classList.add("fade-out");
    appShell.classList.remove("hidden");
    // Remove from DOM after the fade.
    setTimeout(() => splashEl.remove(), 500);
  }, 1600);
});

// Re-scan cats when the window regains focus (matches Mac-app behavior).
window.addEventListener("focus", () => { cats.refresh(); });

// ---------------------------------------------------------------------------
// Tray actions forwarded from Rust → control the timer from the menu bar
// ---------------------------------------------------------------------------

listen<string>("tray-action", (event) => {
  switch (event.payload) {
    case "toggle": timer.toggle(); break;
    case "reset":  timer.reset();  break;
    case "skip":   timer.skip();   break;
  }
});
