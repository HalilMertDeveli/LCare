import Link from "next/link";

import { StatusBadge } from "@/components/status-badge";
import type { ServiceRequestSummary } from "@/lib/api/types";
import { formatDateTime, t } from "@/lib/i18n";

/** Dense operational table of organization requests (scrolls horizontally on phones). */
export function AdminRequestTable({ items }: { items: ServiceRequestSummary[] }) {
  if (items.length === 0) {
    return (
      <p className="rounded-md border border-dashed p-6 text-center text-sm text-muted-foreground">
        {t.admin.empty}
      </p>
    );
  }
  return (
    <div className="overflow-x-auto rounded-md border bg-card">
      <table className="w-full min-w-[720px] text-sm">
        <thead className="bg-muted/60 text-left text-xs font-medium text-muted-foreground">
          <tr>
            <th scope="col" className="px-3 py-2">{t.requests.referenceCode}</th>
            <th scope="col" className="px-3 py-2">{t.requests.title}</th>
            <th scope="col" className="px-3 py-2">{t.requests.customer}</th>
            <th scope="col" className="px-3 py-2">{t.requests.status}</th>
            <th scope="col" className="px-3 py-2">{t.requests.createdAt}</th>
            <th scope="col" className="px-3 py-2">{t.requests.updatedAt}</th>
          </tr>
        </thead>
        <tbody className="divide-y">
          {items.map((item) => (
            <tr
              key={item.id}
              data-testid="request-row"
              data-reference={item.referenceCode}
              className="hover:bg-muted/40"
            >
              <td className="px-3 py-2 font-mono text-xs whitespace-nowrap">
                <Link
                  href={`/yonetim/talepler/${item.id}`}
                  className="text-primary underline-offset-2 hover:underline"
                >
                  {item.referenceCode}
                </Link>
              </td>
              <td className="max-w-[320px] px-3 py-2">
                <Link href={`/yonetim/talepler/${item.id}`} className="line-clamp-1 hover:underline">
                  {item.title}
                </Link>
              </td>
              <td className="px-3 py-2 whitespace-nowrap">{item.customerName}</td>
              <td className="px-3 py-2">
                <StatusBadge status={item.status} />
              </td>
              <td className="px-3 py-2 text-xs whitespace-nowrap text-muted-foreground tabular-nums">
                {formatDateTime(item.createdAt)}
              </td>
              <td className="px-3 py-2 text-xs whitespace-nowrap text-muted-foreground tabular-nums">
                {formatDateTime(item.updatedAt)}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
