import {
  type AuthSession,
  InvalidCredentialsError,
  type LoginCredentials,
} from "../domain/auth";

const API_BASE_URL = import.meta.env.VITE_API_URL ?? "http://localhost:8000";

/**
 * Modo de autenticación (variable `VITE_AUTH_MODE` en `.env`):
 * - "api"  (por defecto): llama al backend FastAPI en
 *          POST /websocket/users/authenticate.
 * - "mock": simula la petición en el navegador, sin backend ni base de datos.
 *
 * Credenciales de prueba FICTICIAS del modo "mock" (no existen en ningún
 * sistema real; sirven solo para probar la pantalla):
 *   usuario: demo                 contraseña: demo1234
 *   correo:  demo@scrumplanning.test   contraseña: demo1234
 */
const AUTH_MODE: "api" | "mock" =
  import.meta.env.VITE_AUTH_MODE === "mock" ? "mock" : "api";

const MOCK_USERS: ReadonlyArray<{ identifiers: string[]; password: string }> = [
  { identifiers: ["demo", "demo@scrumplanning.test"], password: "demo1234" },
];

const MOCK_DELAY_MS = 1200;

interface TokenResponseDto {
  access_token: string;
  token_type: string;
  message_user: string;
}

interface ErrorResponseDto {
  detail?: string;
}

async function loginWithApi(
  credentials: LoginCredentials,
): Promise<AuthSession> {
  const response = await fetch(`${API_BASE_URL}/websocket/users/authenticate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    // El backend recibe el identificador (usuario o correo) como `userName`.
    body: JSON.stringify({
      userName: credentials.identifier,
      userPassword: credentials.password,
    }),
  });

  if (response.status === 401) {
    throw new InvalidCredentialsError();
  }

  if (!response.ok) {
    const body = (await response.json().catch(() => ({}))) as ErrorResponseDto;
    throw new Error(body.detail ?? `HTTP Error ${response.status}`);
  }

  const data = (await response.json()) as TokenResponseDto;
  return {
    accessToken: data.access_token,
    tokenType: data.token_type,
    userName: credentials.identifier,
  };
}

async function loginWithMock(
  credentials: LoginCredentials,
): Promise<AuthSession> {
  await new Promise((resolve) => setTimeout(resolve, MOCK_DELAY_MS));

  const identifier = credentials.identifier.trim().toLowerCase();
  const user = MOCK_USERS.find(
    (candidate) =>
      candidate.identifiers.includes(identifier) &&
      candidate.password === credentials.password,
  );

  if (!user) {
    throw new InvalidCredentialsError();
  }

  return {
    accessToken: "mock-token",
    tokenType: "bearer",
    userName: credentials.identifier.trim(),
  };
}

export function login(credentials: LoginCredentials): Promise<AuthSession> {
  return AUTH_MODE === "mock"
    ? loginWithMock(credentials)
    : loginWithApi(credentials);
}

// --- Persistencia de la sesión ---------------------------------------------
// "Recordar sesión" guarda en localStorage (sobrevive al cerrar el navegador);
// si no, en sessionStorage (se borra al cerrar la pestaña).

const SESSION_KEY = "scrum-planning.session";

function isAuthSession(value: unknown): value is AuthSession {
  if (typeof value !== "object" || value === null) return false;
  const record = value as Record<string, unknown>;
  return (
    typeof record.accessToken === "string" &&
    typeof record.tokenType === "string" &&
    typeof record.userName === "string"
  );
}

export function saveSession(session: AuthSession, remember: boolean): void {
  try {
    clearSession();
    const storage = remember ? localStorage : sessionStorage;
    storage.setItem(SESSION_KEY, JSON.stringify(session));
  } catch {
    // Almacenamiento bloqueado (modo privado, etc.): la sesión vive solo en memoria.
  }
}

export function loadSession(): AuthSession | null {
  try {
    const raw =
      localStorage.getItem(SESSION_KEY) ?? sessionStorage.getItem(SESSION_KEY);
    if (!raw) return null;
    const parsed: unknown = JSON.parse(raw);
    return isAuthSession(parsed) ? parsed : null;
  } catch {
    return null;
  }
}

export function clearSession(): void {
  try {
    localStorage.removeItem(SESSION_KEY);
    sessionStorage.removeItem(SESSION_KEY);
  } catch {
    // Nada que limpiar si el almacenamiento no está disponible.
  }
}
