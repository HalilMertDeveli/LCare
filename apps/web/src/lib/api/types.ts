/**
 * API DTO types. These are aliases of the types generated from the API's OpenAPI document
 * (`packages/contracts/ts/api.d.ts`, regenerate with `npm --prefix packages/contracts run generate`).
 * Do not hand-write DTO shapes here.
 */
import type { components } from "@contracts/api";

type Schemas = components["schemas"];

export type MeResponse = Schemas["MeResponse"];
export type Membership = Schemas["MembershipDto"];
export type OrganizationRole = Schemas["OrganizationRole"];
export type ServiceRequestStatus = Schemas["ServiceRequestStatus"];
export type ServiceRequestSummary = Schemas["ServiceRequestSummaryDto"];
export type ServiceRequestDetail = Schemas["ServiceRequestDetailDto"];
export type StatusHistory = Schemas["StatusHistoryDto"];
export type ServiceRequestPage = Schemas["PagedResultOfServiceRequestSummaryDto"];
export type CreateServiceRequestBody = Schemas["CreateServiceRequestRequest"];
export type ChangeStatusBody = Schemas["ChangeStatusRequest"];
export type LoginBody = Schemas["LoginRequest"];

/** All statuses in workflow order (typed against the generated union). */
export const SERVICE_REQUEST_STATUSES = [
  "New",
  "InReview",
  "InProgress",
  "WaitingForCustomer",
  "Resolved",
  "Closed",
  "Cancelled",
] as const satisfies readonly ServiceRequestStatus[];
