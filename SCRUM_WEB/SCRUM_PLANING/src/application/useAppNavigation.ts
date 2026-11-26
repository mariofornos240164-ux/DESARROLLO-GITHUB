import { useCallback, useEffect, useState } from "react";

function normalizePath(path: string): string {
  const normalized = path.replace(/\/+$/, "");
  return normalized || "/home";
}

export function useAppNavigation() {
  const [pathname, setPathname] = useState(() =>
    normalizePath(window.location.pathname),
  );

  useEffect(() => {
    const handlePopState = () => {
      setPathname(normalizePath(window.location.pathname));
    };

    window.addEventListener("popstate", handlePopState);
    return () => window.removeEventListener("popstate", handlePopState);
  }, []);

  const navigate = useCallback((path: string) => {
    const nextPath = normalizePath(path);
    if (normalizePath(window.location.pathname) !== nextPath) {
      window.history.pushState({}, "", nextPath);
    }
    setPathname(nextPath);
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, []);

  return { pathname, navigate };
}
