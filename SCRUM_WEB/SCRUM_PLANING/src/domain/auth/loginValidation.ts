import type { Credentials } from "./entities";

// Reglas de validación puras del dominio: sin React ni efectos secundarios,
// así que se pueden reutilizar en cualquier capa y probar por separado.

/** Campos de las credenciales que se validan. */
export type CredentialField = keyof Credentials;

/** Mensaje de error por campo; `undefined` significa que el campo es válido. */
export type CredentialErrors = Partial<Record<CredentialField, string>>;

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
export const MIN_USERNAME_LENGTH = 3;
export const MIN_PASSWORD_LENGTH = 6;

export function validateIdentifier(value: string): string | undefined {
  const trimmed = value.trim();

  if (trimmed === "") {
    return "El correo electrónico o usuario es obligatorio";
  }

  if (trimmed.includes("@")) {
    return EMAIL_PATTERN.test(trimmed)
      ? undefined
      : "Introduce un correo electrónico válido";
  }

  if (/\s/.test(trimmed)) {
    return "El usuario no puede contener espacios";
  }

  if (trimmed.length < MIN_USERNAME_LENGTH) {
    return `El usuario debe tener al menos ${MIN_USERNAME_LENGTH} caracteres`;
  }

  return undefined;
}

export function validatePassword(value: string): string | undefined {
  if (value === "") {
    return "La contraseña es obligatoria";
  }

  if (value.length < MIN_PASSWORD_LENGTH) {
    return `La contraseña debe tener al menos ${MIN_PASSWORD_LENGTH} caracteres`;
  }

  return undefined;
}

export function validateCredentialField(
  field: CredentialField,
  credentials: Credentials,
): string | undefined {
  return field === "identifier"
    ? validateIdentifier(credentials.identifier)
    : validatePassword(credentials.password);
}

export function validateCredentials(credentials: Credentials): CredentialErrors {
  const errors: CredentialErrors = {};
  const identifierError = validateIdentifier(credentials.identifier);
  const passwordError = validatePassword(credentials.password);

  if (identifierError) errors.identifier = identifierError;
  if (passwordError) errors.password = passwordError;

  return errors;
}

export function hasErrors(errors: CredentialErrors): boolean {
  return Object.values(errors).some(Boolean);
}
