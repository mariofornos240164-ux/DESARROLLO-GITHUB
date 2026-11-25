import { useState } from "react";
import { Eye, EyeOff, Loader2, Lock, User } from "lucide-react";
import { toast } from "sonner";
import { useLoginForm } from "../../application/useLoginForm";
import type { AuthSession } from "../../domain/auth";

interface LoginFormProps {
  onAuthenticated: (session: AuthSession) => void;
}

const baseInputClass =
  "block w-full rounded-lg border bg-white py-2.5 pl-10 text-sm text-slate-900 placeholder:text-slate-400 shadow-sm transition focus:outline-none focus:ring-2 disabled:cursor-not-allowed disabled:bg-slate-50";
const validInputClass = "border-slate-300 focus:border-sky-500 focus:ring-sky-500/30";
const invalidInputClass = "border-red-500 focus:border-red-500 focus:ring-red-500";

export function LoginForm({ onAuthenticated }: LoginFormProps) {
  const {
    values,
    errors,
    isSubmitting,
    setFieldValue,
    setRememberSession,
    handleBlur,
    handleSubmit,
  } = useLoginForm(onAuthenticated);
  const [showPassword, setShowPassword] = useState(false);

  const handleForgotPassword = () => {
    // Todavía no existe la ruta de recuperación de contraseña.
    toast.info("La recuperación de contraseña estará disponible próximamente");
  };

  return (
    <form noValidate onSubmit={handleSubmit} className="space-y-5">
      <div>
        <label htmlFor="login-identifier" className="mb-1.5 block text-sm font-medium text-slate-700">
          Correo electrónico o usuario
        </label>
        <div className="relative">
          <User
            aria-hidden="true"
            className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400"
          />
          <input
            id="login-identifier"
            name="identifier"
            type="text"
            inputMode="email"
            autoComplete="username"
            autoCapitalize="none"
            spellCheck={false}
            placeholder="usuario o correo@ejemplo.com"
            value={values.identifier}
            onChange={(e) => setFieldValue("identifier", e.target.value)}
            onBlur={() => handleBlur("identifier")}
            disabled={isSubmitting}
            aria-invalid={errors.identifier ? true : undefined}
            aria-describedby={errors.identifier ? "login-identifier-error" : undefined}
            className={`${baseInputClass} pr-3 ${errors.identifier ? invalidInputClass : validInputClass}`}
          />
        </div>
        {errors.identifier && (
          <p id="login-identifier-error" role="alert" className="mt-1.5 text-xs text-red-600">
            {errors.identifier}
          </p>
        )}
      </div>

      <div>
        <label htmlFor="login-password" className="mb-1.5 block text-sm font-medium text-slate-700">
          Contraseña
        </label>
        <div className="relative">
          <Lock
            aria-hidden="true"
            className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400"
          />
          <input
            id="login-password"
            name="password"
            type={showPassword ? "text" : "password"}
            autoComplete="current-password"
            placeholder="••••••••"
            value={values.password}
            onChange={(e) => setFieldValue("password", e.target.value)}
            onBlur={() => handleBlur("password")}
            disabled={isSubmitting}
            aria-invalid={errors.password ? true : undefined}
            aria-describedby={errors.password ? "login-password-error" : undefined}
            className={`${baseInputClass} pr-11 ${errors.password ? invalidInputClass : validInputClass}`}
          />
          <button
            type="button"
            onClick={() => setShowPassword((prev) => !prev)}
            aria-label={showPassword ? "Ocultar contraseña" : "Mostrar contraseña"}
            aria-pressed={showPassword}
            className="absolute right-1.5 top-1/2 flex h-8 w-8 -translate-y-1/2 cursor-pointer items-center justify-center rounded-md text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500/40"
          >
            {showPassword ? (
              <EyeOff aria-hidden="true" className="h-4 w-4" />
            ) : (
              <Eye aria-hidden="true" className="h-4 w-4" />
            )}
          </button>
        </div>
        {errors.password && (
          <p id="login-password-error" role="alert" className="mt-1.5 text-xs text-red-600">
            {errors.password}
          </p>
        )}
      </div>

      <div className="flex flex-wrap items-center justify-between gap-2">
        <label className="flex cursor-pointer items-center gap-2 text-sm text-slate-600">
          <input
            type="checkbox"
            name="rememberSession"
            checked={values.rememberSession}
            onChange={(e) => setRememberSession(e.target.checked)}
            disabled={isSubmitting}
            className="h-4 w-4 cursor-pointer rounded border-slate-300 accent-sky-600"
          />
          Recordar sesión
        </label>
        <button
          type="button"
          onClick={handleForgotPassword}
          className="cursor-pointer text-sm font-medium text-sky-700 hover:text-sky-800 hover:underline focus:outline-none focus-visible:underline"
        >
          ¿Olvidaste tu contraseña?
        </button>
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        aria-busy={isSubmitting}
        className="flex w-full cursor-pointer items-center justify-center gap-2 rounded-lg bg-sky-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-sky-600/20 transition hover:bg-sky-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-70"
      >
        {isSubmitting ? (
          <>
            <Loader2 aria-hidden="true" className="h-4 w-4 animate-spin" />
            Iniciando sesión...
          </>
        ) : (
          "Iniciar sesión"
        )}
      </button>
    </form>
  );
}
