import type { AuthRepository, SessionRepository } from "../../domain/auth/AuthRepository";
import {
  type AuthSession,
  type Credentials,
  InvalidCredentialsError,
} from "../../domain/auth/entities";
import {
  type CredentialErrors,
  hasErrors,
  validateCredentials,
} from "../../domain/auth/loginValidation";

// Caso de uso: iniciar sesión. Solo depende de la capa de dominio;
// recibe los repositorios por parámetro (inyección de dependencias).

export interface LoginInput {
  credentials: Credentials;
  rememberSession: boolean;
}

export type LoginResult =
  | { status: "success"; session: AuthSession }
  | { status: "invalid-input"; errors: CredentialErrors }
  | { status: "invalid-credentials" }
  | { status: "service-error" };

export interface LoginUseCase {
  execute(input: LoginInput): Promise<LoginResult>;
}

export function createLoginUseCase(
  authRepository: AuthRepository,
  sessionRepository: SessionRepository,
): LoginUseCase {
  return {
    async execute({ credentials, rememberSession }) {
      const normalized: Credentials = {
        identifier: credentials.identifier.trim(),
        password: credentials.password,
      };

      const errors = validateCredentials(normalized);
      if (hasErrors(errors)) {
        return { status: "invalid-input", errors };
      }

      try {
        const session = await authRepository.login(normalized);
        sessionRepository.save(session, rememberSession);
        return { status: "success", session };
      } catch (error) {
        return error instanceof InvalidCredentialsError
          ? { status: "invalid-credentials" }
          : { status: "service-error" };
      }
    },
  };
}
