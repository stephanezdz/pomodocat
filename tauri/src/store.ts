import { invoke } from "@tauri-apps/api/core";
import { CatAsset, DEFAULT_PREFS, Phase, Preferences } from "./types";

/** Tiny observable: subscribe to an event and broadcast on change. */
class Emitter<T> {
  private subs = new Set<(v: T) => void>();
  emit(v: T) { for (const s of this.subs) s(v); }
  on(fn: (v: T) => void) { this.subs.add(fn); return () => this.subs.delete(fn); }
}

// ---------------------------------------------------------------------------
// Preferences store (persisted to localStorage)
// ---------------------------------------------------------------------------

const PREFS_KEY = "pomodocat.preferences";

export class PrefsStore {
  changed = new Emitter<Preferences>();
  private state: Preferences;

  constructor() {
    this.state = { ...DEFAULT_PREFS, ...this.loadFromStorage() };
  }

  get(): Preferences { return { ...this.state }; }

  set<K extends keyof Preferences>(key: K, value: Preferences[K]) {
    if (this.state[key] === value) return;
    this.state = { ...this.state, [key]: value };
    this.persist();
    this.changed.emit(this.get());
  }

  resetKey<K extends keyof Preferences>(key: K) {
    this.set(key, DEFAULT_PREFS[key]);
  }

  private loadFromStorage(): Partial<Preferences> {
    try {
      const raw = localStorage.getItem(PREFS_KEY);
      return raw ? (JSON.parse(raw) as Partial<Preferences>) : {};
    } catch { return {}; }
  }

  private persist() {
    try { localStorage.setItem(PREFS_KEY, JSON.stringify(this.state)); }
    catch { /* ignore */ }
  }
}

// ---------------------------------------------------------------------------
// Cat library + selection (selection persisted; library scanned via Rust)
// ---------------------------------------------------------------------------

const CAT_SELECTION_KEY = "pomodocat.selectedCatID";

export class CatStore {
  changed = new Emitter<{ cats: CatAsset[]; selectedId: string | null }>();
  cats: CatAsset[] = [];
  selectedId: string | null = localStorage.getItem(CAT_SELECTION_KEY);

  async refresh() {
    try {
      const cats = await invoke<CatAsset[]>("list_cats");
      this.cats = cats;
      // Auto-select first if none selected or stored id is gone.
      if (this.cats.length > 0 && !this.cats.find((c) => c.id === this.selectedId)) {
        this.selectedId = this.cats[0].id;
        this.persist();
      }
      this.changed.emit({ cats: this.cats, selectedId: this.selectedId });
    } catch (e) {
      console.error("list_cats failed", e);
      this.cats = [];
      this.changed.emit({ cats: [], selectedId: this.selectedId });
    }
  }

  select(id: string) {
    if (this.selectedId === id) return;
    this.selectedId = id;
    this.persist();
    this.changed.emit({ cats: this.cats, selectedId: this.selectedId });
  }

  current(): CatAsset | null {
    if (!this.selectedId) return this.cats[0] ?? null;
    return this.cats.find((c) => c.id === this.selectedId) ?? this.cats[0] ?? null;
  }

  /**
   * Build the URL the WebView uses to load a cat. We serve files via our own
   * `cat://` URI scheme (handled in Rust) instead of Tauri's `asset://` —
   * the asset protocol scope was inconsistent on Windows for files outside
   * the per-bundle app data directory.
   */
  toAssetURL(cat: CatAsset): string {
    const url = `cat://localhost/${encodeURIComponent(cat.id)}`;
    console.log("[PomodoCat] cat asset URL:", { id: cat.id, path: cat.path, url });
    return url;
  }

  private persist() {
    if (this.selectedId) localStorage.setItem(CAT_SELECTION_KEY, this.selectedId);
    else localStorage.removeItem(CAT_SELECTION_KEY);
  }
}

// ---------------------------------------------------------------------------
// Pomodoro timer state machine
// ---------------------------------------------------------------------------

export interface TimerState {
  phase: Phase;
  remaining: number; // seconds
  total: number;
  isRunning: boolean;
  completedFocus: number;
}

export class TimerStore {
  changed = new Emitter<TimerState>();
  phaseFinished = new Emitter<Phase>();
  private state: TimerState;
  private intervalId: number | null = null;

  constructor(private prefs: PrefsStore) {
    const total = this.durationFor("focus");
    this.state = {
      phase: "focus",
      remaining: total,
      total,
      isRunning: false,
      completedFocus: 0,
    };

    // When durations change while idle, sync the visible time.
    this.prefs.changed.on(() => this.applyPrefsIfIdle());
  }

  get(): TimerState { return { ...this.state }; }

  toggle() { this.state.isRunning ? this.pause() : this.start(); }

  start() {
    if (this.state.isRunning) return;
    this.state.isRunning = true;
    this.intervalId = window.setInterval(() => this.tick(), 1000);
    this.emit();
  }

  pause() {
    this.state.isRunning = false;
    if (this.intervalId !== null) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
    this.emit();
  }

  reset() {
    this.pause();
    this.state.remaining = this.state.total;
    this.emit();
  }

  skip() { this.finishPhase(false); }

  private tick() {
    if (this.state.remaining > 0) {
      this.state.remaining -= 1;
      this.emit();
    }
    if (this.state.remaining === 0) this.finishPhase(true);
  }

  private finishPhase(triggerOverlay: boolean) {
    this.pause();
    const finished = this.state.phase;
    if (finished === "focus") this.state.completedFocus += 1;

    let next: Phase;
    if (finished === "focus") {
      const cycle = this.prefs.get().sessionsBeforeLongBreak;
      next = this.state.completedFocus % cycle === 0 ? "longBreak" : "shortBreak";
    } else {
      next = "focus";
    }

    this.state.phase = next;
    this.state.total = this.durationFor(next);
    this.state.remaining = this.state.total;
    this.emit();

    if (triggerOverlay && this.prefs.get().autoPlayCatVideo) {
      this.phaseFinished.emit(finished);
    }

    if (this.prefs.get().autoStartNextPhase) this.start();
  }

  private applyPrefsIfIdle() {
    if (this.state.isRunning) return;
    const newDuration = this.durationFor(this.state.phase);
    if (newDuration !== this.state.total) {
      this.state.total = newDuration;
      this.state.remaining = newDuration;
      this.emit();
    }
  }

  private durationFor(phase: Phase): number {
    const p = this.prefs.get();
    switch (phase) {
      case "focus":      return p.focusMinutes * 60;
      case "shortBreak": return p.shortBreakMinutes * 60;
      case "longBreak":  return p.longBreakMinutes * 60;
    }
  }

  private emit() { this.changed.emit(this.get()); }
}
