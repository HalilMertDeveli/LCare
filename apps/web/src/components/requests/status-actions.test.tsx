import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { ApiError } from "@/lib/api/client";
import type { api } from "@/lib/api/endpoints";
import type { ServiceRequestDetail } from "@/lib/api/types";
import { t } from "@/lib/i18n";
import { AdminStatusActions, CustomerCancelAction } from "./status-actions";

type ChangeFn = typeof api.changeStatus;

const base: ServiceRequestDetail = {
  id: "r1",
  referenceCode: "LC-000010",
  title: "Ekran titriyor",
  description: "Akşam saatlerinde titreme oluyor.",
  status: "New",
  customerId: "c",
  customerName: "Örnek",
  createdAt: "2026-10-30T07:00:00Z",
  updatedAt: "2026-10-30T07:00:00Z",
  version: 788,
  allowedTransitions: ["InReview", "InProgress", "Cancelled"],
  history: [],
};

describe("AdminStatusActions", () => {
  it("renders a button only for each allowed transition", () => {
    render(<AdminStatusActions request={base} onChanged={vi.fn()} onStale={vi.fn()} />);
    expect(screen.getByRole("button", { name: "İnceleniyor" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "İşlemde" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "İptal Edildi" })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: "Çözüldü" })).not.toBeInTheDocument();
  });

  it("sends the last-read version and the note", async () => {
    const updated = { ...base, status: "InReview" as const, version: 789 };
    const changeStatus = vi.fn<ChangeFn>().mockResolvedValue(updated);
    const onChanged = vi.fn();
    render(
      <AdminStatusActions
        request={base}
        onChanged={onChanged}
        onStale={vi.fn()}
        changeStatus={changeStatus}
      />,
    );
    const user = userEvent.setup();
    await user.type(screen.getByLabelText(t.admin.noteLabel), "  Kontrol ediliyor ");
    await user.click(screen.getByRole("button", { name: "İnceleniyor" }));
    expect(changeStatus).toHaveBeenCalledWith("r1", {
      status: "InReview",
      version: 788,
      note: "Kontrol ediliyor",
    });
    expect(onChanged).toHaveBeenCalledWith(updated);
    expect(await screen.findByText(t.admin.changed("İnceleniyor"))).toBeInTheDocument();
  });

  it("on 409 shows 'kayıt güncel değil' and reloads", async () => {
    const changeStatus = vi.fn<ChangeFn>().mockRejectedValue(new ApiError("conflict", 409));
    const onStale = vi.fn();
    render(
      <AdminStatusActions
        request={base}
        onChanged={vi.fn()}
        onStale={onStale}
        changeStatus={changeStatus}
      />,
    );
    await userEvent.setup().click(screen.getByRole("button", { name: "İşlemde" }));
    expect(await screen.findByText(/Kayıt güncel değil/)).toBeInTheDocument();
    expect(onStale).toHaveBeenCalledTimes(1);
  });

  it("shows an empty state for terminal statuses", () => {
    render(
      <AdminStatusActions
        request={{ ...base, status: "Closed", allowedTransitions: [] }}
        onChanged={vi.fn()}
        onStale={vi.fn()}
      />,
    );
    expect(screen.getByText(t.admin.noActions)).toBeInTheDocument();
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });
});

describe("CustomerCancelAction", () => {
  it("is hidden unless Cancelled is an allowed transition", () => {
    const { container } = render(
      <CustomerCancelAction
        request={{ ...base, status: "InProgress", allowedTransitions: [] }}
        onChanged={vi.fn()}
        onStale={vi.fn()}
      />,
    );
    expect(container).toBeEmptyDOMElement();
  });

  it("asks for confirmation, then cancels", async () => {
    const changeStatus = vi
      .fn<ChangeFn>()
      .mockResolvedValue({ ...base, status: "Cancelled", allowedTransitions: [], version: 789 });
    render(
      <CustomerCancelAction
        request={{ ...base, allowedTransitions: ["Cancelled"] }}
        onChanged={vi.fn()}
        onStale={vi.fn()}
        changeStatus={changeStatus}
      />,
    );
    const user = userEvent.setup();
    await user.click(screen.getByRole("button", { name: t.customer.cancel }));
    expect(screen.getByText(t.customer.cancelConfirm)).toBeInTheDocument();
    expect(changeStatus).not.toHaveBeenCalled();
    await user.click(screen.getByRole("button", { name: t.customer.cancel }));
    expect(changeStatus).toHaveBeenCalledWith("r1", { status: "Cancelled", version: 788, note: null });
  });
});
