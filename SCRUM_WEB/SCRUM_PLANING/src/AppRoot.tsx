import { useEffect, useState } from "react";
import App from "./App.tsx";
import type { AuthSession } from "./domain/auth/entities";
import { authUseCases } from "./infrastructure/auth/authContainer";
import { LoginPage } from "./presentation/auth/LoginPage";

/** Muestra el Login hasta que haya una sesión; después, la app de Scrum. */
export default function AppRoot() {
  const [session, setSession] = useState<AuthSession | null>(() =>
    authUseCases.getCurrentSession.execute(),
  );
  const [isDarkMode, setIsDarkMode] = useState(() => {
    const savedTheme = window.localStorage.getItem("scrum-planning-theme");
    return savedTheme
      ? savedTheme === "dark"
      : window.matchMedia("(prefers-color-scheme: dark)").matches;
  });

  useEffect(() => {
    document.documentElement.classList.toggle("dark", isDarkMode);
    window.localStorage.setItem(
      "scrum-planning-theme",
      isDarkMode ? "dark" : "light",
    );
  }, [isDarkMode]);

  const handleLogout = () => {
    authUseCases.logout.execute();
    setSession(null);
  };

  return session ? (
    <App
      userName={session.user.userName}
      onLogout={handleLogout}
      isDarkMode={isDarkMode}
      onToggleTheme={() => setIsDarkMode((previous) => !previous)}
    />
  ) : (
    <LoginPage
      loginUseCase={authUseCases.login}
      onAuthenticated={setSession}
      isDarkMode={isDarkMode}
      onToggleTheme={() => setIsDarkMode((previous) => !previous)}
    />
  );
}
