import { useState } from "react";
import { Toaster } from "sonner";
import App from "./App.tsx";
import type { AuthSession } from "./domain/auth";
import { clearSession, loadSession } from "./infrastructure/authApi";
import { LoginPage } from "./presentation/auth/LoginPage";

/** Muestra el Login hasta que haya una sesión; después, la app de Scrum. */
export default function AppRoot() {
  const [session, setSession] = useState<AuthSession | null>(() => loadSession());

  const handleLogout = () => {
    clearSession();
    setSession(null);
  };

  return (
    <>
      {session ? (
        <App userName={session.userName} onLogout={handleLogout} />
      ) : (
        <LoginPage onAuthenticated={setSession} />
      )}
      <Toaster position="top-right" richColors />
    </>
  );
}
