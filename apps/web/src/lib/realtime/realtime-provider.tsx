"use client";

import {
  HubConnectionBuilder,
  HubConnectionState,
  LogLevel,
  type HubConnection,
} from "@microsoft/signalr";
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";

import type { ServiceRequestStatus } from "@/lib/api/types";

export type ConnectionState = "connecting" | "connected" | "reconnecting" | "disconnected";

/** Payload of the server → client `serviceRequestChanged` event (a hint, not data). */
export interface ServiceRequestChangedEvent {
  serviceRequestId: string;
  organizationId: string;
  change: "created" | "statusChanged";
  status: ServiceRequestStatus;
  version: number;
  occurredAt: string;
}

export type RefreshReason =
  | { type: "event"; event: ServiceRequestChangedEvent }
  | { type: "connected" }
  | { type: "focus" };

type Listener = (reason: RefreshReason) => void;

interface RealtimeContextValue {
  state: ConnectionState;
  subscribe: (listener: Listener) => () => void;
}

const RealtimeContext = createContext<RealtimeContextValue | null>(null);

export const HUB_PATH = "/hubs/notifications";
const RETRY_DELAYS_MS = [0, 2_000, 5_000, 10_000, 30_000];

/**
 * Owns the SignalR connection to `/hubs/notifications` (same origin via the Next.js rewrite,
 * authenticated by the session cookie). Components subscribe with `useRealtimeRefresh` and
 * re-fetch from REST on events, after (re)connecting and when the tab regains focus —
 * events missed while disconnected are not replayed by the server.
 *
 * Transport: the client negotiates WebSockets first and automatically falls back to
 * Server-Sent Events, then Long Polling, if a transport cannot be established.
 */
export function RealtimeProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<ConnectionState>("connecting");
  const listeners = useRef(new Set<Listener>());

  const emit = useCallback((reason: RefreshReason) => {
    for (const listener of listeners.current) listener(reason);
  }, []);

  useEffect(() => {
    let disposed = false;
    let retryTimer: ReturnType<typeof setTimeout> | undefined;
    let attempt = 0;

    const connection: HubConnection = new HubConnectionBuilder()
      .withUrl(HUB_PATH, { withCredentials: true })
      .withAutomaticReconnect(RETRY_DELAYS_MS)
      .configureLogging(LogLevel.Warning)
      .build();

    connection.on("serviceRequestChanged", (event: ServiceRequestChangedEvent) => {
      emit({ type: "event", event });
    });
    connection.onreconnecting(() => {
      if (!disposed) setState("reconnecting");
    });
    connection.onreconnected(() => {
      if (disposed) return;
      setState("connected");
      emit({ type: "connected" });
    });
    connection.onclose(() => {
      if (disposed) return;
      // Automatic reconnect gave up (or the server closed us): keep trying with backoff.
      setState("disconnected");
      scheduleStart();
    });

    function scheduleStart() {
      const delay = RETRY_DELAYS_MS[Math.min(attempt, RETRY_DELAYS_MS.length - 1)] || 1_000;
      attempt += 1;
      retryTimer = setTimeout(() => void start(), delay);
    }

    async function start() {
      if (disposed || connection.state !== HubConnectionState.Disconnected) return;
      setState(attempt === 0 ? "connecting" : "reconnecting");
      try {
        await connection.start();
        if (disposed) return;
        attempt = 0;
        setState("connected");
        // Anything that changed between the initial REST load and now is picked up here.
        emit({ type: "connected" });
      } catch {
        if (disposed) return;
        setState("disconnected");
        scheduleStart();
      }
    }

    const onFocus = () => emit({ type: "focus" });
    const onVisibility = () => {
      if (document.visibilityState === "visible") {
        emit({ type: "focus" });
        if (connection.state === HubConnectionState.Disconnected) {
          // Coming back to the tab: retry right away instead of waiting for the backoff.
          if (retryTimer) clearTimeout(retryTimer);
          retryTimer = undefined;
          void start();
        }
      }
    };
    window.addEventListener("focus", onFocus);
    document.addEventListener("visibilitychange", onVisibility);

    // Deferred one tick so React StrictMode's mount/unmount/mount in development does not
    // start (and immediately abort) a negotiation.
    retryTimer = setTimeout(() => void start(), 0);

    return () => {
      disposed = true;
      if (retryTimer) clearTimeout(retryTimer);
      window.removeEventListener("focus", onFocus);
      document.removeEventListener("visibilitychange", onVisibility);
      void connection.stop().catch(() => undefined);
    };
  }, [emit]);

  const subscribe = useCallback((listener: Listener) => {
    listeners.current.add(listener);
    return () => {
      listeners.current.delete(listener);
    };
  }, []);

  const value = useMemo(() => ({ state, subscribe }), [state, subscribe]);
  return <RealtimeContext.Provider value={value}>{children}</RealtimeContext.Provider>;
}

export function useConnectionState(): ConnectionState {
  return useContext(RealtimeContext)?.state ?? "disconnected";
}

/**
 * Calls `onRefresh` whenever the data may be stale (realtime event, reconnect, focus).
 * Use `filter` to ignore events that cannot affect the current view.
 */
export function useRealtimeRefresh(
  onRefresh: (reason: RefreshReason) => void,
  filter?: (event: ServiceRequestChangedEvent) => boolean,
): void {
  const ctx = useContext(RealtimeContext);
  const callback = useRef(onRefresh);
  const filterRef = useRef(filter);
  useEffect(() => {
    callback.current = onRefresh;
    filterRef.current = filter;
  });

  const subscribe = ctx?.subscribe;
  useEffect(() => {
    if (!subscribe) return;
    return subscribe((reason) => {
      if (reason.type === "event" && filterRef.current && !filterRef.current(reason.event)) return;
      callback.current(reason);
    });
  }, [subscribe]);
}
