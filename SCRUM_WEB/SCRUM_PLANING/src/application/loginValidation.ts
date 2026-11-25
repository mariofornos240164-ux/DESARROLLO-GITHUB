import type { LoginField, LoginFormErrors, LoginFormValues } from "../domain/auth";

// Lógica de validación pura: no depende de React ni de la vista,
// así que se puede reutilizar y probar por separado.

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const MIN_USERNAME_LENGTH = 3;
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

export function validateLoginField(
  field: LoginField,
  values: LoginFormValues,
): string | undefined {
  return field === "identifier"
    ? validateIdentifier(values.identifier)
    : validatePassword(values.password);
}

export function validateLoginForm(values: LoginFormValues): LoginFormErrors {
  const errors: LoginFormErrors = {};
  const identifierError = validateIdentifier(values.identifier);
  const passwordError = validatePassword(values.password);

  if (identifierError) errors.identifier = identifierError;
  if (passwordError) errors.password = passwordError;

  return errors;
}

export function hasErrors(errors: LoginFormErrors): boolean {
  return Object.values(errors).some(Boolean);
}
