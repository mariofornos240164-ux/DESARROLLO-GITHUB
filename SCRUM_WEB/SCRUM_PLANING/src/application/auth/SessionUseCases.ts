import type { SessionRepository } from "../../domain/auth/AuthRepository";
import type { AuthSession } from "../../domain/auth/entities";

// Casos de uso de la sesión actual: recuperarla al cargar la app y cerrarla.

export interface GetCurrentSessionUseCase {
  execute(): AuthSession | null;
}

export interface LogoutUseCase {
  execute(): void;
}

export function createGetCurrentSessionUseCase(
  sessionRepository: SessionRepository,
): GetCurrentSessionUseCase {
  return { execute: () => sessionRepository.load() };
}

export function createLogoutUseCase(
  sessionRepository: SessionRepository,
): LogoutUseCase {
  return { execute: () => sessionRepository.clear() };
}
