import type { Credentials } from "./entities";

// Reglas de validación puras del dominio: sin React ni efectos secundarios,
// así que se pueden reutilizar en cualquier capa y probar por separado.

/** Campos de las credenciales que se validan. */
export type CredentialField = keyof Credentials;

/** Mensaje de error por campo; `undefined` significa que el campo es válido. */
export type CredentialErrors = Partial<Record<CredentialField, string>>;

export interface CredentialValidationMessages {
  identifierRequired: string;
  invalidEmail: string;
  identifierWhitespace: string;
  usernameMinLength: (minimum: number) => string;
  passwordRequired: string;
  passwordMinLength: (minimum: number) => string;
}

export const DEFAULT_CREDENTIAL_VALIDATION_MESSAGES: CredentialValidationMessages = {
  identifierRequired: "El correo electrónico o usuario es obligatorio",
  invalidEmail: "Introduce un correo electrónico válido",
  identifierWhitespace: "El usuario no puede contener espacios",
  usernameMinLength: (minimum) =>
    `El usuario debe tener al menos ${minimum} caracteres`,
  passwordRequired: "La contraseña es obligatoria",
  passwordMinLength: (minimum) =>
    `La contraseña debe tener al menos ${minimum} caracteres`,
};

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
export const MIN_USERNAME_LENGTH = 3;
export const MIN_PASSWORD_LENGTH = 6;

export function validateIdentifier(
  value: string,
  messages: CredentialValidationMessages = DEFAULT_CREDENTIAL_VALIDATION_MESSAGES,
): string | undefined {
  const trimmed = value.trim();

  if (trimmed === "") {
    return messages.identifierRequired;
  }

  if (trimmed.includes("@")) {
    return EMAIL_PATTERN.test(trimmed)
      ? undefined
      : messages.invalidEmail;
  }

  if (/\s/.test(trimmed)) {
    return messages.identifierWhitespace;
  }

  if (trimmed.length < MIN_USERNAME_LENGTH) {
    return messages.usernameMinLength(MIN_USERNAME_LENGTH);
  }

  return undefined;
}

export function validatePassword(
  value: string,
  messages: CredentialValidationMessages = DEFAULT_CREDENTIAL_VALIDATION_MESSAGES,
): string | undefined {
  if (value === "") {
    return messages.passwordRequired;
  }

  if (value.length < MIN_PASSWORD_LENGTH) {
    return messages.passwordMinLength(MIN_PASSWORD_LENGTH);
  }

  return undefined;
}

export function validateCredentialField(
  field: CredentialField,
  credentials: Credentials,
  messages: CredentialValidationMessages = DEFAULT_CREDENTIAL_VALIDATION_MESSAGES,
): string | undefined {
  return field === "identifier"
    ? validateIdentifier(credentials.identifier, messages)
    : validatePassword(credentials.password, messages);
}

export function validateCredentials(
  credentials: Credentials,
  messages: CredentialValidationMessages = DEFAULT_CREDENTIAL_VALIDATION_MESSAGES,
): CredentialErrors {
  const errors: CredentialErrors = {};
  const identifierError = validateIdentifier(credentials.identifier, messages);
  const passwordError = validatePassword(credentials.password, messages);

  if (identifierError) errors.identifier = identifierError;
  if (passwordError) errors.password = passwordError;

  return errors;
}

export function hasErrors(errors: CredentialErrors): boolean {
  return Object.values(errors).some(Boolean);
}
