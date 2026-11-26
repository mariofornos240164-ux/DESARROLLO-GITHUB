import type { LoginUseCase } from "../../application/auth/LoginUseCase";
import type { AuthSession } from "../../domain/auth/entities";
import type { CredentialValidationMessages } from "../../domain/auth/loginValidation";
import { BrandLogo } from "./BrandLogo";
import { LoginForm } from "./LoginForm";
import { ThemeToggle } from "../ThemeToggle";

interface LoginPageProps {
  loginUseCase: LoginUseCase;
  onAuthenticated: (session: AuthSession) => void;
  validationMessages?: CredentialValidationMessages;
  isDarkMode: boolean;
  onToggleTheme: () => void;
}

export function LoginPage({
  loginUseCase,
  onAuthenticated,
  validationMessages,
  isDarkMode,
  onToggleTheme,
}: LoginPageProps) {
  return (
    <main className="login-screen relative min-h-screen w-full bg-linear-to-br from-sky-200/80 via-white to-blue-200/80 px-5 py-10 sm:px-8 lg:px-12">
      <div className="absolute right-5 top-5 z-10 sm:right-8 lg:right-12">
        <ThemeToggle isDarkMode={isDarkMode} onToggle={onToggleTheme} />
      </div>
      <div className="mx-auto grid min-h-[calc(100vh-5rem)] w-full max-w-6xl items-center gap-12 lg:grid-cols-[1fr_0.85fr] lg:gap-20">
        <section className="mx-auto w-full max-w-xl lg:mx-0">
          <BrandLogo className="mb-8" />
          <p className="max-w-lg text-base leading-7 text-slate-600 sm:text-lg">
            Organiza el trabajo de tu equipo en un solo lugar: prioriza el
            backlog, planifica sprints y sigue cada tarea hasta su entrega.
          </p>

          <div className="relative mt-10 overflow-hidden rounded-3xl border border-white/80 bg-white/70 p-5 shadow-xl shadow-sky-200/50 backdrop-blur-sm sm:p-7">
            <div
              aria-hidden="true"
              className="absolute -right-10 -top-12 h-40 w-40 rounded-full bg-sky-200/70 blur-3xl"
            />
            <div className="relative">
              <p className="text-xs font-semibold uppercase tracking-[0.16em] text-sky-700">
                Un flujo de trabajo, de principio a fin
              </p>
              <div className="mt-5 grid gap-3 sm:grid-cols-3">
                {[
                  {
                    number: "01",
                    title: "Backlog",
                    description: "Prioriza ideas y define qué aporta valor.",
                  },
                  {
                    number: "02",
                    title: "Sprints",
                    description: "Planifica el trabajo con objetivos claros.",
                  },
                  {
                    number: "03",
                    title: "Entregas",
                    description: "Visualiza el avance y celebra resultados.",
                  },
                ].map((step) => (
                  <div
                    key={step.number}
                    className="rounded-2xl border border-slate-100 bg-white/85 p-4 shadow-sm"
                  >
                    <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-sky-100 text-xs font-bold text-sky-700">
                      {step.number}
                    </span>
                    <h2 className="mt-4 text-sm font-semibold text-slate-800">
                      {step.title}
                    </h2>
                    <p className="mt-1 text-xs leading-5 text-slate-500">
                      {step.description}
                    </p>
                  </div>
                ))}
              </div>
              <div className="mt-5 flex items-center gap-3 border-t border-slate-200/80 pt-4">
                <div aria-hidden="true" className="flex -space-x-2">
                  <span className="h-7 w-7 rounded-full border-2 border-white bg-sky-500" />
                  <span className="h-7 w-7 rounded-full border-2 border-white bg-blue-500" />
                  <span className="h-7 w-7 rounded-full border-2 border-white bg-indigo-400" />
                </div>
                <p className="text-xs leading-5 text-slate-500">
                  <span className="font-semibold text-slate-700">
                    Más claridad para todo el equipo.
                  </span>{" "}
                  Un mismo lugar para avanzar juntos.
                </p>
              </div>
            </div>
          </div>
        </section>

        <div className="mx-auto w-full max-w-md">
          <section
            aria-labelledby="login-title"
            className="rounded-2xl border border-slate-200/80 bg-white/90 p-6 shadow-xl shadow-sky-200/40 sm:p-8"
          >
            <header className="mb-6">
              <h1
                id="login-title"
                className="text-xl font-semibold text-slate-900"
              >
                Inicia sesión
              </h1>
              <p className="mt-1 text-sm text-slate-500">
                Accede a tus backlogs, sprints y tareas del equipo.
              </p>
            </header>

            <LoginForm
              loginUseCase={loginUseCase}
              onAuthenticated={onAuthenticated}
              validationMessages={validationMessages}
            />
          </section>

          <p className="mt-6 text-center text-xs text-slate-400">
            © {new Date().getFullYear()} Scrum Planning
          </p>
        </div>
      </div>
    </main>
  );
}
