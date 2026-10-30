import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { ApiError } from "@/lib/api/client";
import type { ServiceRequestDetail } from "@/lib/api/types";
import { t } from "@/lib/i18n";
import { ServiceRequestForm } from "./service-request-form";

const created: ServiceRequestDetail = {
  id: "1",
  referenceCode: "LC-000042",
  title: "Ekran kararıyor",
  description: "Sol alt köşede görüntü yok.",
  status: "New",
  customerId: "c",
  customerName: "Örnek Reklam A.Ş.",
  createdAt: "2026-10-30T07:00:00Z",
  updatedAt: "2026-10-30T07:00:00Z",
  version: 1,
  allowedTransitions: ["Cancelled"],
  history: [],
};

function setup(submit = vi.fn().mockResolvedValue(created)) {
  const onCreated = vi.fn();
  render(<ServiceRequestForm submit={submit} onCreated={onCreated} />);
  return {
    user: userEvent.setup(),
    submit,
    onCreated,
    title: screen.getByLabelText(t.requests.title),
    description: screen.getByLabelText(t.requests.description),
    button: screen.getByRole("button", { name: t.customer.submit }),
  };
}

describe("ServiceRequestForm", () => {
  it("blocks submission and shows Turkish messages when fields are too short", async () => {
    const { user, submit, title, description, button } = setup();
    await user.type(title, "abc");
    await user.type(description, "kısa");
    await user.click(button);
    expect(screen.getByText(t.customer.titleTooShort)).toBeInTheDocument();
    expect(screen.getByText(t.customer.descriptionTooShort)).toBeInTheDocument();
    expect(submit).not.toHaveBeenCalled();
  });

  it("validates trimmed lengths (whitespace does not count)", async () => {
    const { user, submit, title, description, button } = setup();
    await user.type(title, "   ab   ");
    await user.type(description, "Yeterince uzun bir açıklama");
    await user.click(button);
    expect(screen.getByText(t.customer.titleTooShort)).toBeInTheDocument();
    expect(submit).not.toHaveBeenCalled();
  });

  it("rejects titles over 150 characters", async () => {
    const { user, submit, title, description, button } = setup();
    await user.click(title);
    await user.paste("x".repeat(151));
    await user.type(description, "Yeterince uzun bir açıklama");
    await user.click(button);
    expect(screen.getByText(t.customer.titleTooLong)).toBeInTheDocument();
    expect(submit).not.toHaveBeenCalled();
  });

  it("submits trimmed values and reports the new reference code", async () => {
    const { user, submit, onCreated, title, description, button } = setup();
    await user.type(title, "  Ekran kararıyor ");
    await user.type(description, "Sol alt köşede görüntü yok.");
    await user.click(button);
    expect(submit).toHaveBeenCalledWith({
      title: "Ekran kararıyor",
      description: "Sol alt köşede görüntü yok.",
    });
    expect(onCreated).toHaveBeenCalledWith(created);
    expect(await screen.findByText(t.customer.created("LC-000042"))).toBeInTheDocument();
    expect(title).toHaveValue("");
  });

  it("shows server-side validation errors", async () => {
    const submit = vi.fn().mockRejectedValue(
      new ApiError("validation", 400, {
        status: 400,
        errors: { Description: ["The field Description must be ..."] },
      }),
    );
    const { user, title, description, button } = setup(submit);
    await user.type(title, "Geçerli başlık");
    await user.type(description, "Geçerli açıklama metni");
    await user.click(button);
    expect(await screen.findByText("The field Description must be ...")).toBeInTheDocument();
    expect(screen.getByText(t.errors.validation)).toBeInTheDocument();
  });

  it("shows a network error message when the API is unreachable", async () => {
    const submit = vi.fn().mockRejectedValue(new ApiError("network", 0));
    const { user, title, description, button } = setup(submit);
    await user.type(title, "Geçerli başlık");
    await user.type(description, "Geçerli açıklama metni");
    await user.click(button);
    expect(await screen.findByText(t.errors.network)).toBeInTheDocument();
  });
});
