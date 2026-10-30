import { t } from "@/lib/i18n";

/** Client-side limits mirroring the API (CreateServiceRequestRequest / ChangeStatusRequest). */
export const LIMITS = {
  titleMin: 5,
  titleMax: 150,
  descriptionMin: 10,
  descriptionMax: 4000,
  noteMax: 1000,
} as const;

export interface ServiceRequestInput {
  title: string;
  description: string;
}

export type ServiceRequestErrors = Partial<Record<keyof ServiceRequestInput, string>>;

/** Lengths are checked on the trimmed value, which is what gets sent. */
export function validateServiceRequest(input: ServiceRequestInput): ServiceRequestErrors {
  const errors: ServiceRequestErrors = {};
  const title = input.title.trim();
  const description = input.description.trim();
  if (title.length < LIMITS.titleMin) errors.title = t.customer.titleTooShort;
  else if (title.length > LIMITS.titleMax) errors.title = t.customer.titleTooLong;
  if (description.length < LIMITS.descriptionMin) errors.description = t.customer.descriptionTooShort;
  else if (description.length > LIMITS.descriptionMax)
    errors.description = t.customer.descriptionTooLong;
  return errors;
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function validateLogin(email: string, password: string): { email?: string; password?: string } {
  const errors: { email?: string; password?: string } = {};
  if (email.trim().length === 0) errors.email = t.login.emailRequired;
  else if (!EMAIL_RE.test(email.trim())) errors.email = t.login.emailInvalid;
  if (password.length === 0) errors.password = t.login.passwordRequired;
  return errors;
}
