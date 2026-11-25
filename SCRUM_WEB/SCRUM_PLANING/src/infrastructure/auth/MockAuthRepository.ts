import type { AuthRepository } from "../../domain/auth/AuthRepository";
import {
  type AuthSession,
  type Credentials,
  InvalidCredentialsError,
} from "../../domain/auth/entities";

/**
 * Implementación simulada para trabajar sin backend ni base de datos
 * (se activa con VITE_AUTH_MODE=mock en `.env`).
 *
 * Credenciales de prueba FICTICIAS (no existen en ningún sistema real;
 * sirven solo para probar la pantalla):
 *   usuario: demo                       contraseña: demo1234
 *   correo:  demo@scrumplanning.test    contraseña: demo1234
 */
const MOCK_USERS: ReadonlyArray<{ identifiers: string[]; password: string }> = [
  { identifiers: ["demo", "demo@scrumplanning.test"], password: "demo1234" },
];

export function createMockAuthRepository(delayMs = 1200): AuthRepository {
  return {
    async login(credentials: Credentials): Promise<AuthSession> {
      await new Promise((resolve) => setTimeout(resolve, delayMs));

      const identifier = credentials.identifier.toLowerCase();
      const user = MOCK_USERS.find(
        (candidate) =>
          candidate.identifiers.includes(identifier) &&
          candidate.password === credentials.password,
      );

      if (!user) {
        throw new InvalidCredentialsError();
      }

      return {
        user: { userName: credentials.identifier },
        accessToken: "mock-token",
        tokenType: "bearer",
      };
    },
  };
}
