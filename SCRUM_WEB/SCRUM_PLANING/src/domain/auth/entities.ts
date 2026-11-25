// Capa de dominio: entidades y errores de autenticación.
// No depende de React, del navegador ni de ninguna otra capa.

/** Credenciales con las que el usuario intenta iniciar sesión. */
export interface Credentials {
  /** Correo electrónico o nombre de usuario. */
  identifier: string;
  password: string;
}

/** Usuario autenticado. */
export interface User {
  userName: string;
}

/** Sesión obtenida tras un inicio de sesión correcto. */
export interface AuthSession {
  user: User;
  accessToken: string;
  tokenType: string;
}

/** El servicio rechazó las credenciales (usuario o contraseña incorrectos). */
export class InvalidCredentialsError extends Error {
  constructor(message = "Credenciales incorrectas") {
    super(message);
    this.name = "InvalidCredentialsError";
  }
}

/** No se pudo completar la autenticación (red caída, error del servidor...). */
export class AuthServiceError extends Error {
  constructor(message = "No se pudo conectar con el servicio de autenticación") {
    super(message);
    this.name = "AuthServiceError";
  }
}
