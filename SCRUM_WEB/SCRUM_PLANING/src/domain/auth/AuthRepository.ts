import type { AuthSession, Credentials } from "./entities";

/**
 * Puerto (interfaz) que el dominio define y la infraestructura implementa.
 * Las implementaciones deben lanzar `InvalidCredentialsError` si el usuario o
 * la contraseña no son correctos, y `AuthServiceError` ante cualquier otro fallo.
 */
export interface AuthRepository {
  login(credentials: Credentials): Promise<AuthSession>;
}

/** Puerto para guardar la sesión entre recargas de la página. */
export interface SessionRepository {
  /** `remember` = conservar la sesión aunque se cierre el navegador. */
  save(session: AuthSession, remember: boolean): void;
  load(): AuthSession | null;
  clear(): void;
}
