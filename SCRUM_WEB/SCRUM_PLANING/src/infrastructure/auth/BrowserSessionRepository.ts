import type { SessionRepository } from "../../domain/auth/AuthRepository";
import type { AuthSession } from "../../domain/auth/entities";

// "Recordar sesión" guarda en localStorage (sobrevive al cerrar el navegador);
// si no, en sessionStorage (se borra al cerrar la pestaña).

const SESSION_KEY = "scrum-planning.session";

function isAuthSession(value: unknown): value is AuthSession {
  if (typeof value !== "object" || value === null) return false;
  const record = value as Record<string, unknown>;
  const user = record.user as Record<string, unknown> | null | undefined;
  return (
    typeof record.accessToken === "string" &&
    typeof record.tokenType === "string" &&
    typeof user === "object" &&
    user !== null &&
    typeof user.userName === "string"
  );
}

export function createBrowserSessionRepository(): SessionRepository {
  const clear = () => {
    try {
      localStorage.removeItem(SESSION_KEY);
      sessionStorage.removeItem(SESSION_KEY);
    } catch {
      // Almacenamiento no disponible: no hay nada que limpiar.
    }
  };

  return {
    save(session, remember) {
      try {
        clear();
        const storage = remember ? localStorage : sessionStorage;
        storage.setItem(SESSION_KEY, JSON.stringify(session));
      } catch {
        // Almacenamiento bloqueado (modo privado, etc.): la sesión vive solo en memoria.
      }
    },
    load() {
      try {
        const raw =
          localStorage.getItem(SESSION_KEY) ?? sessionStorage.getItem(SESSION_KEY);
        if (!raw) return null;
        const parsed: unknown = JSON.parse(raw);
        return isAuthSession(parsed) ? parsed : null;
      } catch {
        return null;
      }
    },
    clear,
  };
}
