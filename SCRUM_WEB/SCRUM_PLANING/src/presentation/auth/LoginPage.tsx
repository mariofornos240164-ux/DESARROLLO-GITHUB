import type { LoginUseCase } from "../../application/auth/LoginUseCase";
import type { AuthSession } from "../../domain/auth/entities";
import { BrandLogo } from "./BrandLogo";
import { LoginForm } from "./LoginForm";

interface LoginPageProps {
  loginUseCase: LoginUseCase;
  onAuthenticated: (session: AuthSession) => void;
}

export function LoginPage({ loginUseCase, onAuthenticated }: LoginPageProps) {
  return (
    <main className="flex min-h-screen w-full items-center justify-center bg-gradient-to-br from-slate-50 via-white to-sky-50 px-4 py-10 sm:px-6">
      <div className="w-full max-w-md">
        <BrandLogo className="mb-8" />

        <section
          aria-labelledby="login-title"
          className="rounded-2xl border border-slate-200/80 bg-white/90 p-6 shadow-xl shadow-slate-200/50 backdrop-blur-sm sm:p-8"
        >
          <header className="mb-6">
            <h1 id="login-title" className="text-xl font-semibold text-slate-900">
              Inicia sesión
            </h1>
            <p className="mt-1 text-sm text-slate-500">
              Accede a tus backlogs, sprints y tareas del equipo.
            </p>
          </header>

          <LoginForm loginUseCase={loginUseCase} onAuthenticated={onAuthenticated} />
        </section>

        <p className="mt-6 text-center text-xs text-slate-400">
          © {new Date().getFullYear()} Scrum Planning
        </p>
      </div>
    </main>
  );
}
