import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import { SERVICE_REQUEST_STATUSES } from "@/lib/api/types";
import { StatusBadge } from "./status-badge";

const EXPECTED = {
  New: ["Yeni", "blue"],
  InReview: ["İnceleniyor", "violet"],
  InProgress: ["İşlemde", "amber"],
  WaitingForCustomer: ["Müşteri Yanıtı Bekleniyor", "orange"],
  Resolved: ["Çözüldü", "green"],
  Closed: ["Kapatıldı", "slate"],
  Cancelled: ["İptal Edildi", "red"],
} as const;

describe("StatusBadge", () => {
  it.each(SERVICE_REQUEST_STATUSES)("shows the Turkish label and colour for %s", (status) => {
    const [label, colour] = EXPECTED[status];
    render(<StatusBadge status={status} />);
    const badge = screen.getByText(label);
    expect(badge).toHaveAttribute("data-status", status);
    expect(badge.className).toContain(`bg-${colour}-`);
  });
});
