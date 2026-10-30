import { describe, expect, it, vi } from "vitest";

import { ApiError, apiFetch, errorMessage, kindFromStatus } from "./client";
import { t } from "@/lib/i18n";

function problemResponse(status: number, body: object) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/problem+json" },
  });
}

describe("kindFromStatus", () => {
  it.each([
    [400, "validation"],
    [401, "unauthorized"],
    [403, "forbidden"],
    [404, "notFound"],
    [409, "conflict"],
    [429, "rateLimited"],
    [500, "server"],
    [502, "server"],
    [418, "unknown"],
  ] as const)("maps %i to %s", (status, kind) => {
    expect(kindFromStatus(status)).toBe(kind);
  });
});

describe("apiFetch", () => {
  it("returns parsed JSON and sends same-origin credentials", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({ ok: 1 }), { status: 200, headers: { "content-type": "application/json" } }),
    );
    vi.stubGlobal("fetch", fetchMock);
    await expect(apiFetch("/api/me")).resolves.toEqual({ ok: 1 });
    expect(fetchMock).toHaveBeenCalledWith(
      "/api/me",
      expect.objectContaining({ credentials: "same-origin", cache: "no-store" }),
    );
  });

  it("serialises the json body", async () => {
    const fetchMock = vi.fn().mockResolvedValue(new Response(null, { status: 204 }));
    vi.stubGlobal("fetch", fetchMock);
    await apiFetch("/api/x", { method: "POST", json: { a: "ş" } });
    const init = fetchMock.mock.calls[0][1] as RequestInit;
    expect(init.body).toBe(JSON.stringify({ a: "ş" }));
    expect(new Headers(init.headers).get("content-type")).toBe("application/json");
  });

  it.each([
    [401, "unauthorized", t.errors.unauthorized],
    [403, "forbidden", t.errors.forbidden],
    [404, "notFound", t.errors.notFound],
    [409, "conflict", t.errors.conflict],
    [429, "rateLimited", t.errors.rateLimited],
    [500, "server", t.errors.server],
  ] as const)("maps HTTP %i to an ApiError(%s) with a Turkish message", async (status, kind, message) => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(problemResponse(status, { status, title: "x" })));
    const error = await apiFetch("/api/x").catch((e: unknown) => e);
    expect(error).toBeInstanceOf(ApiError);
    expect((error as ApiError).kind).toBe(kind);
    expect((error as ApiError).status).toBe(status);
    expect(errorMessage(error)).toBe(message);
  });

  it("maps a failed fetch (API unreachable) to a network error", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new TypeError("Failed to fetch")));
    const error = await apiFetch("/api/x").catch((e: unknown) => e);
    expect((error as ApiError).kind).toBe("network");
    expect(errorMessage(error)).toBe(t.errors.network);
  });

  it("exposes validation errors with camelCase keys", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(
        problemResponse(400, { status: 400, errors: { Title: ["too short"], description: ["bad"] } }),
      ),
    );
    const error = (await apiFetch("/api/x").catch((e: unknown) => e)) as ApiError;
    expect(error.kind).toBe("validation");
    expect(error.fieldErrors).toEqual({ title: ["too short"], description: ["bad"] });
  });

  it("tolerates non-JSON error bodies", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(new Response("Bad gateway", { status: 502 })));
    const error = (await apiFetch("/api/x").catch((e: unknown) => e)) as ApiError;
    expect(error.kind).toBe("server");
    expect(error.problem).toBeUndefined();
  });

  it("uses a generic message for non-API errors", () => {
    expect(errorMessage(new Error("boom"))).toBe(t.errors.unknown);
  });
});
