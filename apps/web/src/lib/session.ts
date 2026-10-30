import type { MeResponse, OrganizationRole } from "@/lib/api/types";

export type Shell = "staff" | "customer" | "technician" | "none";

const STAFF_ROLES: readonly OrganizationRole[] = ["ServiceManager", "Dispatcher"];
const TECHNICIAN_ROLES: readonly OrganizationRole[] = [
  "RemoteSupportTechnician",
  "FieldTechnician",
];

/**
 * Picks the UI shell from `GET /api/me` (see docs/api/contracts.md):
 * staff = PlatformSuperAdmin or ServiceManager/Dispatcher; customer = Customer;
 * technician = Remote/Field technician only. This is UX routing only — the API authorizes.
 */
export function resolveShell(me: MeResponse): Shell {
  const roles = me.memberships.flatMap((m) => m.roles);
  if (me.platformRoles.includes("PlatformSuperAdmin") || roles.some((r) => STAFF_ROLES.includes(r))) {
    return "staff";
  }
  if (roles.includes("Customer")) return "customer";
  if (roles.some((r) => TECHNICIAN_ROLES.includes(r))) return "technician";
  return "none";
}

export const SHELL_HOME: Record<Exclude<Shell, "none">, string> = {
  staff: "/yonetim",
  customer: "/musteri",
  technician: "/teknisyen",
};

export const SESSION_COOKIE = "ledcare_session";

/** Only allow same-site relative paths as post-login redirect targets. */
export function safeNextPath(next: string | null | undefined, shell: Exclude<Shell, "none">): string {
  const home = SHELL_HOME[shell];
  if (!next || !next.startsWith("/") || next.startsWith("//") || next.startsWith("/\\")) return home;
  return next === home || next.startsWith(`${home}/`) ? next : home;
}
