import type { AuthRepository } from "../../domain/auth/AuthRepository";
import {
  type AuthSession,
  AuthServiceError,
  type Credentials,
  InvalidCredentialsError,
} from "../../domain/auth/entities";

/** Respuesta del backend FastAPI (`TokenResponse` en generic_states.py). */
interface TokenResponseDto {
  access_token: string;
  token_type: string;
  message_user: string;
  user_name?: string;
}

/**
 * Implementación real: POST {apiBaseUrl}/websocket/users/authenticate.
 * El backend recibe el identificador (usuario o correo) como `userName`.
 */
export function createApiAuthRepository(apiBaseUrl: string): AuthRepository {
  return {
    async login(credentials: Credentials): Promise<AuthSession> {
      let response: Response;
      try {
        response = await fetch(`${apiBaseUrl}/websocket/users/authenticate`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            userName: credentials.identifier,
            userPassword: credentials.password,
          }),
        });
      } catch {
        throw new AuthServiceError();
      }

      if (response.status === 401) {
        throw new InvalidCredentialsError();
      }

      if (!response.ok) {
        throw new AuthServiceError(`HTTP Error ${response.status}`);
      }

      const data = (await response.json()) as TokenResponseDto;
      return {
        user: { userName: data.user_name ?? credentials.identifier },
        accessToken: data.access_token,
        tokenType: data.token_type,
      };
    },
  };
}
