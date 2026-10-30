import type { Metadata } from "next";

import { AppShell } from "@/components/app-shell";
import { t } from "@/lib/i18n";

// Authenticated, client-rendered area: content depends on the session (resolved in the
// browser via /api/me), so it is not part of a static shell. Opt out of instant-nav validation.
export const instant = false;

export const metadata: Metadata = {
  title: t.shell.technicianArea,
  robots: { index: false, follow: false },
};

export default function Layout({ children }: LayoutProps<"/teknisyen">) {
  return <AppShell area="technician">{children}</AppShell>;
}
