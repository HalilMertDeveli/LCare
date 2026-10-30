import { render, screen, within } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import type { ServiceRequestSummary } from "@/lib/api/types";
import { t } from "@/lib/i18n";
import { AdminRequestTable } from "./admin-request-table";

const items: ServiceRequestSummary[] = [
  {
    id: "a1",
    referenceCode: "LC-000001",
    title: "Ekranda ölü pikseller",
    status: "InReview",
    customerId: "c1",
    customerName: "Örnek Reklam A.Ş.",
    createdAt: "2026-10-30T07:12:06Z",
    updatedAt: "2026-10-30T08:00:00Z",
    version: 3,
  },
  {
    id: "b2",
    referenceCode: "LC-000002",
    title: "Modül arızası",
    status: "New",
    customerId: "c2",
    customerName: "Demo Otel Turizm",
    createdAt: "2026-10-30T09:00:00Z",
    updatedAt: "2026-10-30T09:00:00Z",
    version: 1,
  },
];

describe("AdminRequestTable", () => {
  it("renders one row per request with reference, title, customer and status", () => {
    render(<AdminRequestTable items={items} />);
    const rows = screen.getAllByTestId("request-row");
    expect(rows).toHaveLength(2);

    const first = within(rows[0]);
    expect(first.getByRole("link", { name: "LC-000001" })).toHaveAttribute(
      "href",
      "/yonetim/talepler/a1",
    );
    expect(first.getByText("Ekranda ölü pikseller")).toBeInTheDocument();
    expect(first.getByText("Örnek Reklam A.Ş.")).toBeInTheDocument();
    expect(first.getByText("İnceleniyor")).toBeInTheDocument();

    expect(within(rows[1]).getByText("Yeni")).toBeInTheDocument();
    expect(within(rows[1]).getByText("Demo Otel Turizm")).toBeInTheDocument();
  });

  it("has Turkish column headers", () => {
    render(<AdminRequestTable items={items} />);
    for (const header of [t.requests.referenceCode, t.requests.customer, t.requests.status]) {
      expect(screen.getByRole("columnheader", { name: header })).toBeInTheDocument();
    }
  });

  it("shows an empty state", () => {
    render(<AdminRequestTable items={[]} />);
    expect(screen.getByText(t.admin.empty)).toBeInTheDocument();
  });
});
