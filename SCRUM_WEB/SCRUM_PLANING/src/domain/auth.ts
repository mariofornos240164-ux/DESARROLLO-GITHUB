/** Valores que el usuario escribe en el formulario de inicio de sesión. */
export interface LoginFormValues {
  /** Correo electrónico o nombre de usuario. */
  identifier: string;
  password: string;
  rememberSession: boolean;
}

/** Campos del formulario que se validan. */
export type LoginField = "identifier" | "password";

/** Mensaje de error por campo; `undefined` significa que el campo es válido. */
export type LoginFormErrors = Partial<Record<LoginField, string>>;

/** Campos que el usuario ya visitó (para mostrar errores solo tras `onBlur`). */
export type LoginTouchedFields = Partial<Record<LoginField, boolean>>;

/** Credenciales que se envían al servicio de autenticación. */
export interface LoginCredentials {
  identifier: string;
  password: string;
}

/** Sesión obtenida tras un inicio de sesión correcto. */
export interface AuthSession {
  accessToken: string;
  tokenType: string;
  userName: string;
}

/** Error de credenciales rechazadas por el servicio (HTTP 401). */
export class InvalidCredentialsError extends Error {
  constructor(message = "Credenciales incorrectas") {
    super(message);
    this.name = "InvalidCredentialsError";
  }
}
