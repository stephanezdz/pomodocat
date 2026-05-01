import { invoke } from "@tauri-apps/api/core";
import { getCurrentWindow } from "@tauri-apps/api/window";

interface OverlayCat {
  path: string;
  kind: string;          // "video" | "image"
  sound_enabled: boolean;
}

const stage = document.getElementById("stage") as HTMLDivElement;
const closeBtn = document.getElementById("close-btn") as HTMLButtonElement;

async function init() {
  const cat = await invoke<OverlayCat | null>("get_overlay_cat");

  if (!cat) {
    const fallback = document.createElement("div");
    fallback.className = "fallback";
    fallback.textContent = "🐱";
    stage.appendChild(fallback);
    return;
  }

  // Use the same custom `cat://` scheme as the main window. Derive the
  // filename from the absolute path (handles both / and \\ separators).
  const filename = cat.path.split(/[\\/]/).pop() ?? "";
  const url = `cat://localhost/${encodeURIComponent(filename)}`;
  console.log("[PomodoCat overlay] cat URL:", { path: cat.path, url });

  if (cat.kind === "video") {
    const video = document.createElement("video");
    video.src = url;
    video.autoplay = true;
    video.loop = true;
    video.muted = !cat.sound_enabled;
    video.playsInline = true;
    // Some browsers block autoplay-with-audio if there's been no user
    // interaction. We try to play, then fall back to muted playback.
    video.play().catch(() => {
      video.muted = true;
      video.play().catch(() => { /* give up silently */ });
    });
    stage.appendChild(video);
  } else {
    const img = document.createElement("img");
    img.src = url;
    stage.appendChild(img);
  }
}

// --- dismissal --------------------------------------------------------------

async function dismiss() {
  // Close via Tauri so the macOS NSWindow tears down properly.
  await getCurrentWindow().close();
}

closeBtn.addEventListener("click", (e) => {
  e.stopPropagation();
  dismiss();
});

// Esc closes (accessibility); clicking anywhere else does NOT close
// (per the SwiftUI behaviour the user asked for).
window.addEventListener("keydown", (e) => {
  if (e.key === "Escape") dismiss();
});

// Don't accidentally drag the window or trigger other gestures.
document.body.addEventListener("contextmenu", (e) => e.preventDefault());

init().catch((err) => {
  console.error("overlay init failed", err);
});
