export type Phase = "focus" | "shortBreak" | "longBreak";

export type CatKind = "video" | "image";

export interface CatAsset {
  id: string;
  path: string;
  display_name: string;
  kind: CatKind;
}

export interface Preferences {
  focusMinutes: number;
  shortBreakMinutes: number;
  longBreakMinutes: number;
  sessionsBeforeLongBreak: number;
  autoPlayCatVideo: boolean;
  catVideoSoundEnabled: boolean;
  autoStartNextPhase: boolean;
}

export const DEFAULT_PREFS: Preferences = {
  focusMinutes: 25,
  shortBreakMinutes: 5,
  longBreakMinutes: 15,
  sessionsBeforeLongBreak: 4,
  autoPlayCatVideo: true,
  catVideoSoundEnabled: true,
  autoStartNextPhase: false,
};

export const PREF_RANGES = {
  focusMinutes: [1, 60] as const,
  shortBreakMinutes: [1, 30] as const,
  longBreakMinutes: [1, 60] as const,
  sessionsBeforeLongBreak: [2, 8] as const,
};

export const PHASE_TITLES: Record<Phase, { title: string; subtitle: string; pillClass: string }> = {
  focus:      { title: "Focus",         subtitle: "Concentre-toi, le chat veille", pillClass: "focus" },
  shortBreak: { title: "Pause courte",  subtitle: "Respire un peu",                pillClass: "break" },
  longBreak:  { title: "Pause longue",  subtitle: "Tu l'as bien mérité",           pillClass: "long" },
};
