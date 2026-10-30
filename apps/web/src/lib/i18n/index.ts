import { tr, type Messages } from "./tr";

/**
 * Minimal message-dictionary i18n. Turkish is the default (and only shipped) locale.
 * Adding English: create `en.ts` exporting an object that satisfies `Messages`, then register it
 * in `dictionaries` below. Components read strings via `t` (or `getMessages(locale)`).
 */
export type Locale = "tr" | "en";
export const defaultLocale: Locale = "tr";

const dictionaries: Partial<Record<Locale, Messages>> = { tr };

export function getMessages(locale: Locale = defaultLocale): Messages {
  return dictionaries[locale] ?? tr;
}

/** Messages for the default locale; usable from server and client components alike. */
export const t: Messages = getMessages();

/** BCP-47 tag used for Intl formatting. */
export const intlLocale: Record<Locale, string> = { tr: "tr-TR", en: "en-GB" };

const dateTimeFormat = new Intl.DateTimeFormat(intlLocale[defaultLocale], {
  dateStyle: "medium",
  timeStyle: "short",
  timeZone: "Europe/Istanbul",
});

export function formatDateTime(iso: string): string {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? iso : dateTimeFormat.format(d);
}

export type { Messages };
