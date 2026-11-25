import { createLoginUseCase } from "../../application/auth/LoginUseCase";
import {
  createGetCurrentSessionUseCase,
  createLogoutUseCase,
} from "../../application/auth/SessionUseCases";
import { createApiAuthRepository } from "./ApiAuthRepository";
import { createBrowserSessionRepository } from "./BrowserSessionRepository";
import { createMockAuthRepository } from "./MockAuthRepository";

// Raíz de composición: el único lugar que conoce las implementaciones
// concretas y las conecta con los casos de uso.
//
// VITE_AUTH_MODE (en `.env`):
//   "api"  (por defecto) → backend FastAPI real.
//   "mock"               → login simulado (ver MockAuthRepository.ts).

const API_BASE_URL = import.meta.env.VITE_API_URL ?? "http://localhost:8000";
const AUTH_MODE = import.meta.env.VITE_AUTH_MODE === "mock" ? "mock" : "api";

const authRepository =
  AUTH_MODE === "mock"
    ? createMockAuthRepository()
    : createApiAuthRepository(API_BASE_URL);
const sessionRepository = createBrowserSessionRepository();

export const authUseCases = {
  login: createLoginUseCase(authRepository, sessionRepository),
  getCurrentSession: createGetCurrentSessionUseCase(sessionRepository),
  logout: createLogoutUseCase(sessionRepository),
};
