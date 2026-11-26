const API_BASE_URL = import.meta.env.VITE_API_URL ?? "http://localhost:8000";
const SESSION_KEY = "scrum-planning.session";

function getAccessToken(): string | null {
  try {
    const raw =
      localStorage.getItem(SESSION_KEY) ?? sessionStorage.getItem(SESSION_KEY);
    if (!raw) return null;
    const session: unknown = JSON.parse(raw);
    if (
      typeof session === "object" &&
      session !== null &&
      "accessToken" in session &&
      typeof session.accessToken === "string"
    ) {
      return session.accessToken;
    }
  } catch {
    return null;
  }
  return null;
}

export async function httpRequest<T>(
  endpoint: string,
  options: RequestInit = {},
): Promise<T> {
  const headers = new Headers(options.headers);
  if (!headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }
  const accessToken = getAccessToken();
  if (accessToken && !headers.has("Authorization")) {
    headers.set("Authorization", `Bearer ${accessToken}`);
  }

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

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
