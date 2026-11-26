import { createBrowserSessionRepository } from "./auth/BrowserSessionRepository";

const API_BASE_URL = import.meta.env.VITE_API_URL ?? "http://localhost:8000";

// La sesión se lee del mismo repositorio que usa el login (una sola fuente).
const sessionRepository = createBrowserSessionRepository();

// Se llama cuando el backend rechaza el token (vencido o inválido).
let unauthorizedHandler: (() => void) | null = null;

export function setUnauthorizedHandler(handler: (() => void) | null): void {
  unauthorizedHandler = handler;
}

export async function httpRequest<T>(
  endpoint: string,
  options: RequestInit = {},
): Promise<T> {
  const headers = new Headers(options.headers);
  if (!headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  const session = sessionRepository.load();
  if (session && !headers.has("Authorization")) {
    headers.set("Authorization", `Bearer ${session.accessToken}`);
  }

  let response: Response;
  try {
    response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers,
    });
  } catch {
    // El navegador solo dice "Failed to fetch": el backend no responde.
    throw new Error("No se pudo conectar con el servidor. Verifica que el backend esté encendido.");
  }

  if (response.status === 401 && session) {
    // El token venció: se cierra la sesión y la app vuelve al login.
    sessionRepository.clear();
    unauthorizedHandler?.();
  }

  if (!response.ok) {
    const errorText = await response.text();
    let message = errorText || `HTTP Error ${response.status}`;
    try {
      const errorBody: unknown = JSON.parse(errorText);
      if (
        typeof errorBody === "object" &&
        errorBody !== null &&
        "detail" in errorBody &&
        typeof errorBody.detail === "string"
      ) {
        message = errorBody.detail;
      }
    } catch (error) {
      if (!(error instanceof SyntaxError)) throw error;
    }
    throw new Error(message);
  }

  if (response.status === 204) {
    return undefined as T;
  }

  return response.json() as Promise<T>;
}
