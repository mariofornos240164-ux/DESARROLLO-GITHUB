import { useState } from "react";
import { Toaster } from "sonner";
import App from "./App.tsx";
import type { AuthSession } from "./domain/auth/entities";
import { authUseCases } from "./infrastructure/auth/authContainer";
import { LoginPage } from "./presentation/auth/LoginPage";

/** Muestra el Login hasta que haya una sesión; después, la app de Scrum. */
export default function AppRoot() {
  const [session, setSession] = useState<AuthSession | null>(() =>
    authUseCases.getCurrentSession.execute(),
  );

  const handleLogout = () => {
    authUseCases.logout.execute();
    setSession(null);
  };

  return (
    <>
      {session ? (
        <App userName={session.user.userName} onLogout={handleLogout} />
      ) : (
        <LoginPage loginUseCase={authUseCases.login} onAuthenticated={setSession} />
      )}
      <Toaster position="top-right" richColors />
    </>
  );
}
