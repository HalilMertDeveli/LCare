import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { ApiError } from "@/lib/api/client";
import type { MeResponse } from "@/lib/api/types";
import { t } from "@/lib/i18n";
import { LoginForm, type LoginFormProps } from "./login-form";

type LoginFn = NonNullable<LoginFormProps["login"]>;

const customer: MeResponse = {
  userId: "u",
  email: "musteri@example.com",
  displayName: "Ayşe",
  platformRoles: [],
  memberships: [
    {
      organizationId: "o",
      organizationName: "Org",
      roles: ["Customer"],
      customerId: "c",
      customerName: "Örnek",
    },
  ],
};

const admin: MeResponse = {
  ...customer,
  platformRoles: ["PlatformSuperAdmin"],
  memberships: [{ ...customer.memberships[0], roles: ["ServiceManager"], customerId: null, customerName: null }],
};

function setup(opts: { login?: LoginFn; me?: MeResponse; next?: string } = {}) {
  const login = opts.login ?? vi.fn<LoginFn>().mockResolvedValue(undefined);
  const meFn = vi.fn().mockResolvedValue(opts.me ?? customer);
  const navigate = vi.fn();
  render(<LoginForm login={login} me={meFn} navigate={navigate} next={opts.next} />);
  return {
    user: userEvent.setup(),
    login,
    navigate,
    email: screen.getByLabelText(t.login.email),
    password: screen.getByLabelText(t.login.password),
    submit: screen.getByRole("button", { name: t.login.submit }),
  };
}

describe("LoginForm", () => {
  it("requires email and password", async () => {
    const { user, submit, login } = setup();
    await user.click(submit);
    expect(screen.getByText(t.login.emailRequired)).toBeInTheDocument();
    expect(screen.getByText(t.login.passwordRequired)).toBeInTheDocument();
    expect(login).not.toHaveBeenCalled();
  });

  it("rejects a malformed email", async () => {
    const { user, submit, email, password } = setup();
    await user.type(email, "not-an-email");
    await user.type(password, "x");
    await user.click(submit);
    expect(screen.getByText(t.login.emailInvalid)).toBeInTheDocument();
  });

  it("logs in and sends a customer to /musteri", async () => {
    const { user, submit, email, password, login, navigate } = setup();
    await user.type(email, " musteri@example.com ");
    await user.type(password, "secret");
    await user.click(submit);
    expect(login).toHaveBeenCalledWith({ email: "musteri@example.com", password: "secret" });
    expect(navigate).toHaveBeenCalledWith("/musteri");
  });

  it("sends staff to /yonetim and honours a valid next path", async () => {
    const { user, submit, email, password, navigate } = setup({ me: admin, next: "/yonetim/talepler/9" });
    await user.type(email, "admin@example.com");
    await user.type(password, "secret");
    await user.click(submit);
    expect(navigate).toHaveBeenCalledWith("/yonetim/talepler/9");
  });

  it("shows a Turkish error on wrong credentials (401)", async () => {
    const login = vi.fn<LoginFn>().mockRejectedValue(new ApiError("unauthorized", 401));
    const { user, submit, email, password, navigate } = setup({ login });
    await user.type(email, "musteri@example.com");
    await user.type(password, "wrong");
    await user.click(submit);
    expect(await screen.findByText(t.login.invalidCredentials)).toBeInTheDocument();
    expect(navigate).not.toHaveBeenCalled();
    expect(submit).toBeEnabled();
  });

  it("shows the rate-limit message on 429", async () => {
    const login = vi.fn<LoginFn>().mockRejectedValue(new ApiError("rateLimited", 429));
    const { user, submit, email, password } = setup({ login });
    await user.type(email, "musteri@example.com");
    await user.type(password, "wrong");
    await user.click(submit);
    expect(await screen.findByText(t.login.rateLimited)).toBeInTheDocument();
  });

  it("shows the network message when the API is unreachable", async () => {
    const login = vi.fn<LoginFn>().mockRejectedValue(new ApiError("network", 0));
    const { user, submit, email, password } = setup({ login });
    await user.type(email, "musteri@example.com");
    await user.type(password, "x");
    await user.click(submit);
    expect(await screen.findByText(t.errors.network)).toBeInTheDocument();
  });
});
