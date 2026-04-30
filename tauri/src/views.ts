import { CatStore, PrefsStore, TimerState, TimerStore } from "./store";
import { CatAsset, PHASE_TITLES, PREF_RANGES, Phase } from "./types";

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function el<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  opts: { class?: string; text?: string; html?: string; attrs?: Record<string, string> } = {}
): HTMLElementTagNameMap[K] {
  const node = document.createElement(tag);
  if (opts.class) node.className = opts.class;
  if (opts.text) node.textContent = opts.text;
  if (opts.html) node.innerHTML = opts.html;
  if (opts.attrs) for (const [k, v] of Object.entries(opts.attrs)) node.setAttribute(k, v);
  return node;
}

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
}

// ---------------------------------------------------------------------------
// Sidebar
// ---------------------------------------------------------------------------

export type SidebarItem = "timer" | "sessions" | "stats" | "settings";

const SIDEBAR_DEF: { id: SidebarItem; label: string; icon: string }[] = [
  { id: "timer",    label: "Timer",         icon: "⏱" },
  { id: "sessions", label: "Sessions",      icon: "📚" },
  { id: "stats",    label: "Statistiques",  icon: "📊" },
  { id: "settings", label: "Réglages",      icon: "⚙︎" },
];

export function renderSidebar(
  container: HTMLElement,
  current: SidebarItem,
  onSelect: (item: SidebarItem) => void
) {
  container.innerHTML = "";
  for (const def of SIDEBAR_DEF) {
    const row = el("div", {
      class: `sidebar-row${def.id === current ? " active" : ""}`,
    });
    row.appendChild(el("span", { class: "sidebar-row-icon", text: def.icon }));
    row.appendChild(el("span", { text: def.label }));
    row.addEventListener("click", () => onSelect(def.id));
    container.appendChild(row);
  }
}

// ---------------------------------------------------------------------------
// Timer view
// ---------------------------------------------------------------------------

export function renderTimerView(container: HTMLElement, timer: TimerStore) {
  container.innerHTML = "";
  const root = el("div", { class: "timer-view" });

  const header = el("div", { class: "timer-header" });
  const titleBlock = el("div");
  const title = el("div", { class: "timer-title" });
  const subtitle = el("div", { class: "timer-subtitle" });
  titleBlock.append(title, subtitle);

  const badge = el("div", { class: "timer-badge" });
  badge.innerHTML = `<span class="flame">●</span> <span class="badge-count"></span>`;

  header.append(titleBlock, badge);

  const card = el("div", { class: "timer-card" });

  const ringRadius = 120;
  const ringCirc = 2 * Math.PI * ringRadius;
  const ring = el("div", { class: "timer-ring" });
  ring.innerHTML = `
    <svg viewBox="0 0 280 280" width="280" height="280">
      <defs>
        <linearGradient id="grad-focus"  x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%"  stop-color="#ff735a"/><stop offset="100%" stop-color="#f24080"/>
        </linearGradient>
        <linearGradient id="grad-break"  x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%"  stop-color="#59bff2"/><stop offset="100%" stop-color="#668cf2"/>
        </linearGradient>
        <linearGradient id="grad-long"   x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%"  stop-color="#8ed98e"/><stop offset="100%" stop-color="#4db3a6"/>
        </linearGradient>
      </defs>
      <circle class="timer-ring-track" cx="140" cy="140" r="${ringRadius}"/>
      <circle class="timer-ring-progress" cx="140" cy="140" r="${ringRadius}"
              stroke-dasharray="${ringCirc}" stroke-dashoffset="${ringCirc}"
              stroke="url(#grad-focus)"/>
    </svg>
    <div class="timer-ring-center">
      <div class="timer-time">25:00</div>
      <div class="timer-state">En pause</div>
    </div>
  `;

  const controls = el("div", { class: "timer-controls" });
  const resetBtn   = el("button", { class: "btn-circle", html: "↻", attrs: { title: "Réinitialiser" } });
  const primaryBtn = el("button", { class: "btn-primary" });
  const skipBtn    = el("button", { class: "btn-circle", html: "⏭", attrs: { title: "Passer" } });
  controls.append(resetBtn, primaryBtn, skipBtn);

  card.append(ring, controls);

  const pills = el("div", { class: "timer-pills" });
  pills.innerHTML = `
    <span class="pill focus" data-phase="focus">
      <span class="pill-dot"></span> Focus <span class="pill-min"></span>
    </span>
    <span class="pill break" data-phase="shortBreak">
      <span class="pill-dot"></span> Pause courte <span class="pill-min"></span>
    </span>
    <span class="pill long" data-phase="longBreak">
      <span class="pill-dot"></span> Pause longue <span class="pill-min"></span>
    </span>
  `;

  root.append(header, card, pills);
  container.appendChild(root);

  // Wire interactions
  primaryBtn.addEventListener("click", () => timer.toggle());
  resetBtn.addEventListener("click", () => timer.reset());
  skipBtn.addEventListener("click", () => timer.skip());

  // Render function — runs on every state change.
  const update = (s: TimerState) => {
    const def = PHASE_TITLES[s.phase];
    title.textContent    = def.title;
    subtitle.textContent = def.subtitle;
    (badge.querySelector(".badge-count") as HTMLElement).textContent =
      `${s.completedFocus} session${s.completedFocus > 1 ? "s" : ""}`;

    (ring.querySelector(".timer-time") as HTMLElement).textContent  = formatTime(s.remaining);
    (ring.querySelector(".timer-state") as HTMLElement).textContent = s.isRunning ? "En cours" : "En pause";

    const progress = s.total > 0 ? 1 - s.remaining / s.total : 0;
    const offset = ringCirc * (1 - progress);
    const ringEl = ring.querySelector(".timer-ring-progress") as SVGCircleElement;
    ringEl.setAttribute("stroke-dashoffset", String(offset));
    ringEl.setAttribute("stroke",
      s.phase === "focus"      ? "url(#grad-focus)" :
      s.phase === "shortBreak" ? "url(#grad-break)" :
                                 "url(#grad-long)"
    );

    primaryBtn.className = `btn-primary${s.phase === "shortBreak" ? " break" : s.phase === "longBreak" ? " long" : ""}`;
    primaryBtn.innerHTML = s.isRunning
      ? `<span>❚❚</span> Pause`
      : `<span>▶</span> Démarrer`;

    // Pill states
    pills.querySelectorAll<HTMLElement>(".pill").forEach((p) => {
      const phase = p.dataset.phase as Phase;
      p.classList.toggle("active", phase === s.phase);
    });
  };

  // Render durations on the pills based on prefs (read once on mount; refreshed on prefs change).
  const updatePillMinutes = (focusMin: number, shortMin: number, longMin: number) => {
    const arr = pills.querySelectorAll<HTMLElement>(".pill .pill-min");
    arr[0].textContent = `${focusMin} min`;
    arr[1].textContent = `${shortMin} min`;
    arr[2].textContent = `${longMin} min`;
  };

  return { update, updatePillMinutes };
}

// ---------------------------------------------------------------------------
// Settings view
// ---------------------------------------------------------------------------

export function renderSettingsView(
  container: HTMLElement,
  prefs: PrefsStore,
  cats: CatStore
) {
  container.innerHTML = "";
  const root = el("div", { class: "settings-view" });

  // Header
  const header = el("div", { class: "settings-header" });
  header.innerHTML = `
    <h2>Réglages</h2>
    <p>Ajuste les durées, les comportements et choisis ton chat</p>
  `;

  // Theory card
  const theoryCard = el("div", { class: "card" });
  theoryCard.innerHTML = `
    <div class="theory-title"><span class="emoji">🍅</span> La technique Pomodoro</div>
    <div class="theory-body">
      Inventée à la fin des années 1980 par Francesco Cirillo, la méthode Pomodoro
      découpe le travail en intervalles courts de concentration intense (25 min)
      séparés par de petites pauses (5 min). Toutes les quatre sessions, on prend
      une pause longue (15 à 30 min). Cette cadence respecte les limites naturelles
      de l'attention et permet de maintenir un rythme soutenable sur la durée.
    </div>
  `;

  // Durations
  const durationsLabel = el("div", { class: "section-label", text: "DURÉES" });
  const durationsCard = el("div", { class: "card" });

  const buildDurationRow = (
    label: string,
    key: keyof Pick<ReturnType<PrefsStore["get"]>, "focusMinutes" | "shortBreakMinutes" | "longBreakMinutes" | "sessionsBeforeLongBreak">,
    range: readonly [number, number],
    unit = "min"
  ) => {
    const row = el("div", { class: "duration-row" });
    row.innerHTML = `
      <div class="duration-label">${label}</div>
      <input type="range" min="${range[0]}" max="${range[1]}" step="1" />
      <div class="duration-value"><span class="value">0</span><span class="unit">${unit}</span></div>
      <button class="btn-reset" title="Réinitialiser">↻</button>
    `;
    const slider = row.querySelector("input") as HTMLInputElement;
    const valueLabel = row.querySelector(".value") as HTMLElement;
    const resetBtn = row.querySelector(".btn-reset") as HTMLButtonElement;

    const sync = () => {
      const v = prefs.get()[key];
      slider.value = String(v);
      valueLabel.textContent = String(v);
      resetBtn.disabled = v === DEFAULT_FOR(key);
    };

    slider.addEventListener("input", () => prefs.set(key, Number(slider.value)));
    resetBtn.addEventListener("click", () => prefs.resetKey(key));
    prefs.changed.on(sync);
    sync();

    return row;
  };

  const DEFAULT_FOR = (k: string) => {
    const fresh = new (Object.getPrototypeOf(prefs).constructor)();
    return fresh.get()[k];
  };

  durationsCard.append(
    buildDurationRow("Focus",        "focusMinutes",            PREF_RANGES.focusMinutes),
    buildDurationRow("Pause courte", "shortBreakMinutes",       PREF_RANGES.shortBreakMinutes),
    buildDurationRow("Pause longue", "longBreakMinutes",        PREF_RANGES.longBreakMinutes),
    buildDurationRow("Pause longue toutes les", "sessionsBeforeLongBreak", PREF_RANGES.sessionsBeforeLongBreak, "sessions")
  );

  // Behavior toggles
  const behaviorLabel = el("div", { class: "section-label", text: "COMPORTEMENT" });
  const behaviorCard = el("div", { class: "card" });

  const buildToggleRow = (
    title: string,
    subtitle: string,
    key: "autoPlayCatVideo" | "catVideoSoundEnabled" | "autoStartNextPhase"
  ) => {
    const row = el("div", { class: "toggle-row" });
    row.innerHTML = `
      <div class="toggle-row-text">
        <div class="toggle-row-title">${title}</div>
        <div class="toggle-row-subtitle">${subtitle}</div>
      </div>
      <div class="toggle"></div>
    `;
    const toggle = row.querySelector(".toggle") as HTMLElement;
    const sync = () => toggle.classList.toggle("on", prefs.get()[key]);
    row.addEventListener("click", () => prefs.set(key, !prefs.get()[key]));
    prefs.changed.on(sync);
    sync();
    return row;
  };

  behaviorCard.append(
    buildToggleRow("Afficher le chat à la fin d'une session",
      "Lance automatiquement la vidéo en plein écran", "autoPlayCatVideo"),
    buildToggleRow("Son de la vidéo",
      "Active le son du chat quand la vidéo se lance", "catVideoSoundEnabled"),
    buildToggleRow("Démarrer la phase suivante automatiquement",
      "Enchaîne focus et pauses sans cliquer", "autoStartNextPhase")
  );

  // Cat library
  const libraryLabel = el("div", { class: "section-label" });
  const libraryCount = el("span", { class: "count" });
  libraryLabel.append(document.createTextNode("CHAT AFFICHÉ À LA FIN"), libraryCount);

  const libraryCard = el("div", { class: "card" });
  const heroEl = el("div", { class: "cat-hero" });
  const gridEl = el("div", { class: "cat-grid" });
  libraryCard.append(heroEl, gridEl);

  const updateLibrary = () => {
    libraryCount.textContent = `${cats.cats.length} disponible${cats.cats.length > 1 ? "s" : ""}`;

    // Hero
    heroEl.innerHTML = "";
    const current = cats.current();
    if (current) {
      heroEl.appendChild(buildMediaElement(current, cats.toAssetURL(current), { muted: true }));
    } else {
      const empty = el("div", { class: "cat-hero-empty" });
      empty.innerHTML = `<span class="emoji">🐱</span>Aucun chat sélectionné`;
      heroEl.appendChild(empty);
    }

    // Grid
    gridEl.innerHTML = "";
    if (cats.cats.length === 0) {
      const empty = el("div", { class: "empty-state" });
      empty.innerHTML = `<span class="emoji">📂</span>Aucun chat trouvé.<br>
        Drop tes vidéos dans le dossier des chats utilisateur.`;
      gridEl.appendChild(empty);
      return;
    }
    for (const cat of cats.cats) {
      const card = el("div", { class: `cat-card${cat.id === cats.selectedId ? " selected" : ""}` });
      const thumb = el("div", { class: "cat-card-thumb" });
      thumb.appendChild(buildMediaElement(cat, cats.toAssetURL(cat), { muted: true }));
      const name = el("div", { class: "cat-card-name" });
      name.innerHTML = `<span>${cat.display_name}</span>`;
      if (cat.id === cats.selectedId) name.appendChild(el("span", { class: "check", text: "✓" }));
      card.append(thumb, name);
      card.addEventListener("click", () => cats.select(cat.id));
      gridEl.appendChild(card);
    }
  };

  cats.changed.on(updateLibrary);
  updateLibrary();

  root.append(header, theoryCard, durationsLabel, durationsCard, behaviorLabel, behaviorCard, libraryLabel, libraryCard);
  container.appendChild(root);
}

// ---------------------------------------------------------------------------
// Placeholder
// ---------------------------------------------------------------------------

export function renderPlaceholder(container: HTMLElement, label: string, icon: string) {
  container.innerHTML = "";
  const root = el("div", { class: "placeholder-view" });
  root.innerHTML = `
    <div class="icon">${icon}</div>
    <div class="title">${label}</div>
    <div>Bientôt disponible.</div>
  `;
  container.appendChild(root);
}

// ---------------------------------------------------------------------------
// Media factory: video or image (used by hero + cat cards in Settings)
// ---------------------------------------------------------------------------

function buildMediaElement(
  cat: CatAsset,
  url: string,
  opts: { muted?: boolean; fillCover?: boolean } = {}
): HTMLElement {
  if (cat.kind === "video") {
    const video = document.createElement("video");
    video.src = url;
    video.autoplay = true;
    video.loop = true;
    video.muted = opts.muted ?? true;
    video.playsInline = true;
    if (opts.fillCover) video.style.objectFit = "cover";
    // Diagnostics — surface load errors via console (right-click → Inspect).
    video.addEventListener("error", () => {
      const err = video.error;
      console.error("[PomodoCat] video error", {
        id: cat.id,
        url,
        code: err?.code,
        message: err?.message,
        readyState: video.readyState,
        networkState: video.networkState,
      });
    });
    video.addEventListener("loadeddata", () => {
      console.log("[PomodoCat] video loaded", cat.id, video.videoWidth, "×", video.videoHeight);
    });
    video.play().catch((e) => {
      console.warn("[PomodoCat] video.play() rejected", cat.id, e);
    });
    return video;
  }
  const img = document.createElement("img");
  img.src = url;
  img.addEventListener("error", () => console.error("[PomodoCat] image error", cat.id, url));
  return img;
}
