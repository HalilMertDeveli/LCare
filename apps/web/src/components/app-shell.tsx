"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { createContext, useContext, useEffect, useState, type ReactNode } from "react";
import { LogOut } from "lucide-react";

import { BrandMark } from "@/components/brand";
import { ConnectionIndicator } from "@/components/connection-indicator";
import { ErrorAlert } from "@/components/error-alert";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api/endpoints";
import type { MeResponse } from "@/lib/api/types";
import { t } from "@/lib/i18n";
import { RealtimeProvider } from "@/lib/realtime/realtime-provider";
import { resolveShell, SHELL_HOME, type Shell } from "@/lib/session";
import { useResource } from "@/lib/use-resource";

const MeContext = createContext<MeResponse | null>(null);

export function useMe(): MeResponse {
  const me = useContext(MeContext);
  if (!me) throw new Error("useMe must be used inside <AppShell>");
  return me;
}

const AREA_LABEL: Record<Exclude<Shell, "none">, string> = {
  staff: t.shell.adminArea,
  customer: t.shell.customerArea,
  technician: t.shell.technicianArea,
};

/**
 * Authenticated area wrapper: loads `/api/me`, routes the user to the shell matching their
 * roles (UX only — the API enforces authorization), renders the header and starts realtime.
 */
export function AppShell({
  area,
  children,
}: {
  area: Exclude<Shell, "none">;
  children: ReactNode;
}) {
  const router = useRouter();
  const me = useResource((signal) => api.me(signal), []);
  const shell = me.data ? resolveShell(me.data) : undefined;
  const wrongArea = shell !== undefined && shell !== "none" && shell !== area;

  useEffect(() => {
    if (wrongArea) router.replace(SHELL_HOME[shell]);
  }, [wrongArea, shell, router]);

  if (me.error) {
    return (
      <CenteredMessage>
        <ErrorAlert error={me.error} onRetry={() => void me.reload()} />
      </CenteredMessage>
    );
  }
  if (!me.data || wrongArea) {
    return <CenteredMessage>{t.shell.loadingSession}</CenteredMessage>;
  }
  if (shell === "none") {
    return (
      <CenteredMessage>
        <ErrorAlert message={t.login.noRole} />
        <LogoutButton variant="outline" />
      </CenteredMessage>
    );
  }

  const membership = me.data.memberships[0];
  const orgLine = membership?.customerName ?? membership?.organizationName;

  return (
    <MeContext.Provider value={me.data}>
      <RealtimeProvider>
        <div className="flex min-h-full flex-col">
          <header className="bg-navy text-navy-foreground">
            <div className="mx-auto flex w-full max-w-7xl flex-wrap items-center gap-x-4 gap-y-2 px-4 py-3 sm:px-6">
              <Link href={SHELL_HOME[area]} className="flex items-center gap-2 font-semibold">
                <BrandMark />
                <span className="sr-only sm:not-sr-only">{t.brand.name}</span>
              </Link>
              <span className="hidden rounded bg-navy-muted px-2 py-0.5 text-xs text-white/80 sm:inline">
                {AREA_LABEL[area]}
              </span>
              <div className="ml-auto flex items-center gap-3 sm:gap-4">
                <ConnectionIndicator className="text-white/80" />
                <div className="hidden text-right text-xs leading-tight md:block">
                  <div className="font-medium text-white" data-testid="current-user">
                    {me.data.displayName}
                  </div>
                  {orgLine ? <div className="text-white/60">{orgLine}</div> : null}
                </div>
                <LogoutButton
                  variant="ghost"
                  className="text-white hover:bg-white/10 hover:text-white"
                />
              </div>
            </div>
          </header>
          <main id="main" className="mx-auto w-full max-w-7xl flex-1 px-4 py-6 sm:px-6">
            {children}
          </main>
        </div>
      </RealtimeProvider>
    </MeContext.Provider>
  );
}

function CenteredMessage({ children }: { children: ReactNode }) {
  return (
    <main
      id="main"
      className="mx-auto flex min-h-[50vh] w-full max-w-md flex-col items-center justify-center gap-4 px-4 text-sm text-muted-foreground"
    >
      {children}
    </main>
  );
}

function LogoutButton({
  variant,
  className,
}: {
  variant: "ghost" | "outline";
  className?: string;
}) {
  const [busy, setBusy] = useState(false);
  async function logout() {
    setBusy(true);
    try {
      await api.logout();
    } catch {
      // Even if the API is unreachable, leave the authenticated area.
    }
    // Full navigation on purpose: drops all in-memory state (data, realtime connection).
    // eslint-disable-next-line @next/next/no-location-assign-relative-destination
    window.location.assign("/giris");
  }
  return (
    <Button size="sm" variant={variant} className={className} onClick={logout} disabled={busy}>
      <LogOut aria-hidden />
      {t.nav.logout}
    </Button>
  );
}
