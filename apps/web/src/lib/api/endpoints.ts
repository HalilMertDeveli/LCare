import { apiFetch } from "./client";
import type {
  ChangeStatusBody,
  CreateServiceRequestBody,
  LoginBody,
  MeResponse,
  ServiceRequestDetail,
  ServiceRequestPage,
  ServiceRequestStatus,
} from "./types";

export const api = {
  login: (body: LoginBody) =>
    apiFetch<void>("/api/auth/login?useCookies=true", { method: "POST", json: body }),

  logout: () => apiFetch<void>("/api/auth/logout", { method: "POST" }),

  me: (signal?: AbortSignal) => apiFetch<MeResponse>("/api/me", { signal }),

  listServiceRequests: (
    params: { status?: ServiceRequestStatus; page?: number; pageSize?: number } = {},
    signal?: AbortSignal,
  ) => {
    const qs = new URLSearchParams();
    if (params.status) qs.set("status", params.status);
    qs.set("page", String(params.page ?? 1));
    qs.set("pageSize", String(params.pageSize ?? 25));
    return apiFetch<ServiceRequestPage>(`/api/service-requests?${qs}`, { signal });
  },

  getServiceRequest: (id: string, signal?: AbortSignal) =>
    apiFetch<ServiceRequestDetail>(`/api/service-requests/${encodeURIComponent(id)}`, { signal }),

  createServiceRequest: (body: CreateServiceRequestBody) =>
    apiFetch<ServiceRequestDetail>("/api/service-requests", { method: "POST", json: body }),

  changeStatus: (id: string, body: ChangeStatusBody) =>
    apiFetch<ServiceRequestDetail>(`/api/service-requests/${encodeURIComponent(id)}/status`, {
      method: "POST",
      json: body,
    }),
};
