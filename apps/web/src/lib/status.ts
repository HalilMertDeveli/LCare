import type { ServiceRequestStatus } from "@/lib/api/types";
import { t } from "@/lib/i18n";

/**
 * Status colours — shared meaning with the mobile app:
 * New=blue, InReview=violet, InProgress=amber, WaitingForCustomer=orange,
 * Resolved=green, Closed=gray, Cancelled=red.
 */
export const STATUS_STYLES: Record<ServiceRequestStatus, { badge: string; dot: string }> = {
  New: { badge: "bg-blue-50 text-blue-800 ring-blue-600/25", dot: "bg-blue-600" },
  InReview: { badge: "bg-violet-50 text-violet-800 ring-violet-600/25", dot: "bg-violet-600" },
  InProgress: { badge: "bg-amber-50 text-amber-900 ring-amber-600/30", dot: "bg-amber-500" },
  WaitingForCustomer: {
    badge: "bg-orange-50 text-orange-900 ring-orange-600/30",
    dot: "bg-orange-500",
  },
  Resolved: { badge: "bg-green-50 text-green-800 ring-green-600/25", dot: "bg-green-600" },
  Closed: { badge: "bg-slate-100 text-slate-700 ring-slate-500/25", dot: "bg-slate-500" },
  Cancelled: { badge: "bg-red-50 text-red-800 ring-red-600/25", dot: "bg-red-600" },
};

export function statusLabel(status: ServiceRequestStatus): string {
  return t.status[status] ?? status;
}
