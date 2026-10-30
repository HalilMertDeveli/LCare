"use client";

import { cn } from "@/lib/utils";
import { t } from "@/lib/i18n";
import { useConnectionState, type ConnectionState } from "@/lib/realtime/realtime-provider";

const DOT: Record<ConnectionState, string> = {
  connected: "bg-green-500",
  connecting: "bg-amber-400 animate-pulse",
  reconnecting: "bg-amber-400 animate-pulse",
  disconnected: "bg-red-500",
};

export function ConnectionIndicator({ className }: { className?: string }) {
  const state = useConnectionState();
  const hint = state === "connected" ? t.realtime.connectedHint : t.realtime.disconnectedHint;
  return (
    <span
      role="status"
      aria-live="polite"
      title={hint}
      data-connection-state={state}
      className={cn("inline-flex items-center gap-1.5 text-xs", className)}
    >
      <span aria-hidden className={cn("size-2 rounded-full", DOT[state])} />
      {t.realtime[state]}
    </span>
  );
}
