import { Wrench } from "lucide-react";

import { t } from "@/lib/i18n";

// Authenticated, client-rendered area: content depends on the session (resolved in the
// browser via /api/me), so it is not part of a static shell. Opt out of instant-nav validation.
export const instant = false;

export default function TechnicianHomePage() {
  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-semibold tracking-tight">{t.technician.title}</h1>
      <div className="flex flex-col items-center gap-3 rounded-lg border border-dashed bg-card p-10 text-center">
        <Wrench aria-hidden className="size-8 text-muted-foreground" />
        <p className="max-w-md text-sm text-muted-foreground">{t.technician.empty}</p>
      </div>
    </div>
  );
}
