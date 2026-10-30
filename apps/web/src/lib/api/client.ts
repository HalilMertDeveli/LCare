/**
 * Thin fetch wrapper for the LEDCare API. All calls are same-origin (`/api/...`) and go through
 * the Next.js rewrite, so the HttpOnly `ledcare_session` cookie is sent automatically.
 * Every failure is normalised into an `ApiError` with a `kind` the UI maps to Turkish text.
 */
import { t, type Messages } from "@/lib/i18n";

export type ApiErrorKind =
  | "unauthorized"
  | "forbidden"
  | "notFound"
  | "conflict"
  | "rateLimited"
  | "validation"
  | "server"
  | "network"
  | "unknown";

/** RFC 9457 problem details as returned by the API. */
export interface ProblemDetails {
  type?: string;
  title?: string;
  status?: number;
  detail?: string;
  errors?: Record<string, string[]>;
  [key: string]: unknown;
}

export class ApiError extends Error {
  readonly kind: ApiErrorKind;
  readonly status: number;
  readonly problem?: ProblemDetails;

  constructor(kind: ApiErrorKind, status: number, problem?: ProblemDetails) {
    super(problem?.detail ?? problem?.title ?? kind);
    this.name = "ApiError";
    this.kind = kind;
    this.status = status;
    this.problem = problem;
  }

  /** Validation errors keyed by lower-camel-case property name (the API may send PascalCase keys). */
  get fieldErrors(): Record<string, string[]> {
    const out: Record<string, string[]> = {};
    for (const [key, messages] of Object.entries(this.problem?.errors ?? {})) {
      const normalised = key.length > 0 ? key[0].toLowerCase() + key.slice(1) : key;
      out[normalised] = [...(out[normalised] ?? []), ...messages];
    }
    return out;
  }
}

export function kindFromStatus(status: number): ApiErrorKind {
  if (status === 400 || status === 422) return "validation";
  if (status === 401) return "unauthorized";
  if (status === 403) return "forbidden";
  if (status === 404) return "notFound";
  if (status === 409) return "conflict";
  if (status === 429) return "rateLimited";
  if (status >= 500) return "server";
  return "unknown";
}

/** Turkish, user-facing message for an error of any kind. */
export function errorMessage(error: unknown, messages: Messages = t): string {
  if (error instanceof ApiError) return messages.errors[error.kind];
  return messages.errors.unknown;
}

export interface ApiRequestInit extends Omit<RequestInit, "body"> {
  /** JSON-serialisable body. */
  json?: unknown;
}

async function readProblem(res: Response): Promise<ProblemDetails | undefined> {
  const type = res.headers.get("content-type") ?? "";
  if (!type.includes("json")) return undefined;
  try {
    return (await res.json()) as ProblemDetails;
  } catch {
    return undefined;
  }
}

export async function apiFetch<T>(path: string, init: ApiRequestInit = {}): Promise<T> {
  const { json, headers, ...rest } = init;
  const finalHeaders = new Headers(headers);
  finalHeaders.set("accept", "application/json");
  if (json !== undefined) finalHeaders.set("content-type", "application/json");

  let res: Response;
  try {
    res = await fetch(path, {
      credentials: "same-origin",
      cache: "no-store",
      ...rest,
      headers: finalHeaders,
      body: json !== undefined ? JSON.stringify(json) : undefined,
    });
  } catch (cause) {
    if (cause instanceof DOMException && cause.name === "AbortError") throw cause;
    throw new ApiError("network", 0);
  }

  if (!res.ok) {
    // The Next.js rewrite answers 500 (or similar) when the API process is down.
    const problem = await readProblem(res);
    throw new ApiError(kindFromStatus(res.status), res.status, problem);
  }

  if (res.status === 204) return undefined as T;
  const text = await res.text();
  return (text.length > 0 ? JSON.parse(text) : undefined) as T;
}

/** Sends the browser to the login page, remembering where the user was. */
export function redirectToLogin(): void {
  if (typeof window === "undefined") return;
  const here = window.location.pathname + window.location.search;
  const next = here.startsWith("/giris") ? "" : `?next=${encodeURIComponent(here)}`;
  // Full navigation on purpose: drops all in-memory state (data, realtime connection).
  // eslint-disable-next-line @next/next/no-location-assign-relative-destination
  window.location.assign(`/giris${next}`);
}
