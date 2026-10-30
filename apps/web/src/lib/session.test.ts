import { describe, expect, it } from "vitest";

import type { MeResponse, OrganizationRole } from "@/lib/api/types";
import { resolveShell, safeNextPath } from "./session";

function me(roles: OrganizationRole[], platformRoles: string[] = []): MeResponse {
  return {
    userId: "u",
    email: "x@y.z",
    displayName: "X",
    platformRoles,
    memberships: [
      { organizationId: "o", organizationName: "Org", roles, customerId: null, customerName: null },
    ],
  };
}

describe("resolveShell", () => {
  it("routes platform admins and managers/dispatchers to staff", () => {
    expect(resolveShell(me([], ["PlatformSuperAdmin"]))).toBe("staff");
    expect(resolveShell(me(["ServiceManager"]))).toBe("staff");
    expect(resolveShell(me(["Dispatcher"]))).toBe("staff");
  });
  it("routes customers to the customer shell", () => {
    expect(resolveShell(me(["Customer"]))).toBe("customer");
  });
  it("routes technician-only users to the technician shell", () => {
    expect(resolveShell(me(["FieldTechnician"]))).toBe("technician");
    expect(resolveShell(me(["RemoteSupportTechnician"]))).toBe("technician");
  });
  it("returns none without roles", () => {
    expect(resolveShell(me([]))).toBe("none");
  });
});

describe("safeNextPath", () => {
  it("keeps paths inside the user's own area", () => {
    expect(safeNextPath("/musteri/talepler/1", "customer")).toBe("/musteri/talepler/1");
  });
  it("ignores other areas, absolute and protocol-relative URLs", () => {
    expect(safeNextPath("/yonetim", "customer")).toBe("/musteri");
    expect(safeNextPath("https://evil.example", "staff")).toBe("/yonetim");
    expect(safeNextPath("//evil.example", "staff")).toBe("/yonetim");
    expect(safeNextPath(null, "technician")).toBe("/teknisyen");
  });
});
