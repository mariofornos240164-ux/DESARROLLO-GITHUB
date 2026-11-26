import { useEffect, useState } from "react";
import { Eye, EyeOff, Info, Loader2, Lock, User, X } from "lucide-react";
import type { LoginUseCase } from "../../application/auth/LoginUseCase";
import type { AuthSession } from "../../domain/auth/entities";
import {
  type CredentialValidationMessages,
  DEFAULT_CREDENTIAL_VALIDATION_MESSAGES,
} from "../../domain/auth/loginValidation";
import { useLoginForm } from "./useLoginForm";

interface LoginFormProps {
  loginUseCase: LoginUseCase;
  onAuthenticated: (session: AuthSession) => void;
  validationMessages?: CredentialValidationMessages;
}

const baseInputClass =
  "peer block w-full rounded-lg border bg-white pb-2.5 pl-10 pr-3 pt-5 text-sm text-slate-900 placeholder:text-transparent shadow-sm transition focus:outline-none focus:ring-2 disabled:cursor-not-allowed disabled:bg-slate-50";
const validInputClass = "border-slate-300 focus:border-sky-500 focus:ring-sky-500/30";
const invalidInputClass = "border-red-500 focus:border-red-500 focus:ring-red-500";

export function LoginForm({
  loginUseCase,
  onAuthenticated,
  validationMessages = DEFAULT_CREDENTIAL_VALIDATION_MESSAGES,
}: LoginFormProps) {
  const {
    values,
    errors,
    isSubmitting,
    message,
    setMessage,
    setFieldValue,
    setRememberSession,
    handleBlur,
    handleSubmit,
  } = useLoginForm(loginUseCase, onAuthenticated, validationMessages);
  const [showPassword, setShowPassword] = useState(false);

  useEffect(() => {
    if (!message) return;
    const timeoutId = window.setTimeout(() => setMessage(null), 5000);
    return () => window.clearTimeout(timeoutId);
  }, [message, setMessage]);

  const handleForgotPassword = () => {
    // Todavía no existe la ruta de recuperación de contraseña.
    setMessage({ type: "info", text: "La recuperación de contraseña estará disponible próximamente" });
  };

  return (
    <form noValidate onSubmit={handleSubmit} className="space-y-5">
      <div>
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
            placeholder=" "
            value={values.identifier}
            onChange={(e) => setFieldValue("identifier", e.target.value)}
            onBlur={() => handleBlur("identifier")}
            disabled={isSubmitting}
            aria-invalid={errors.identifier ? true : undefined}
            aria-describedby={errors.identifier ? "login-identifier-error" : undefined}
            className={`${baseInputClass} pr-3 ${errors.identifier ? invalidInputClass : validInputClass}`}
          />
          <label
            htmlFor="login-identifier"
            className="pointer-events-none absolute left-10 top-1 -translate-y-0 text-xs font-medium text-slate-500 transition-all peer-placeholder-shown:top-1/2 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:text-sm peer-placeholder-shown:font-normal peer-focus:top-1 peer-focus:-translate-y-0 peer-focus:text-xs peer-focus:font-medium peer-focus:text-sky-700"
          >
            Correo electrónico o usuario
          </label>
        </div>
        {errors.identifier && (
          <p id="login-identifier-error" role="alert" className="mt-1.5 text-xs text-red-600">
            {errors.identifier}
          </p>
        )}
      </div>

      <div>
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
            placeholder=" "
            value={values.password}
            onChange={(e) => setFieldValue("password", e.target.value)}
            onBlur={() => handleBlur("password")}
            disabled={isSubmitting}
            aria-invalid={errors.password ? true : undefined}
            aria-describedby={errors.password ? "login-password-error" : undefined}
            className={`${baseInputClass} pr-11 ${errors.password ? invalidInputClass : validInputClass}`}
          />
          <label
            htmlFor="login-password"
            className="pointer-events-none absolute left-10 top-1 -translate-y-0 text-xs font-medium text-slate-500 transition-all peer-placeholder-shown:top-1/2 peer-placeholder-shown:-translate-y-1/2 peer-placeholder-shown:text-sm peer-placeholder-shown:font-normal peer-focus:top-1 peer-focus:-translate-y-0 peer-focus:text-xs peer-focus:font-medium peer-focus:text-sky-700"
          >
            Contraseña
          </label>
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

      {message && (
        <div
          role={message.type === "error" ? "alert" : "status"}
          aria-live={message.type === "error" ? "assertive" : "polite"}
          className={`fixed right-4 top-4 z-50 flex w-[calc(100%-2rem)] max-w-sm items-start gap-3 rounded-xl border p-4 text-sm shadow-lg sm:right-6 sm:top-6 ${
            message.type === "error"
              ? "border-red-200 bg-white text-red-800 shadow-red-900/10"
              : "border-sky-200 bg-white text-sky-800 shadow-sky-900/10"
          }`}
        >
          <Info
            aria-hidden="true"
            className={`mt-0.5 h-4 w-4 shrink-0 ${
              message.type === "error" ? "text-red-600" : "text-sky-600"
            }`}
          />
          <p className="flex-1">{message.text}</p>
          <button
            type="button"
            onClick={() => setMessage(null)}
            aria-label="Cerrar notificación"
            className="cursor-pointer rounded p-0.5 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500/40"
          >
            <X aria-hidden="true" className="h-4 w-4" />
          </button>
        </div>
      )}
    </form>
  );
}
