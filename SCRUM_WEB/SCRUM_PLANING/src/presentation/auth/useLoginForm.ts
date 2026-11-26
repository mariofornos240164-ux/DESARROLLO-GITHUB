import { type FormEvent, useState } from "react";
import type { LoginUseCase } from "../../application/auth/LoginUseCase";
import type { AuthSession } from "../../domain/auth/entities";
import {
  type CredentialErrors,
  type CredentialField,
  type CredentialValidationMessages,
  DEFAULT_CREDENTIAL_VALIDATION_MESSAGES,
  validateCredentialField,
  validateCredentials,
} from "../../domain/auth/loginValidation";

// Hook de la vista: maneja el estado del formulario y el mensaje que se
// muestra arriba del botón (errores o avisos).
// La lógica de negocio (validar, autenticar, guardar sesión) vive en el
// caso de uso `LoginUseCase`, que recibe por parámetro.

/** Estado del formulario de inicio de sesión. */
export interface LoginFormValues {
  identifier: string;
  password: string;
  rememberSession: boolean;
}

/** Campos que el usuario ya visitó (los errores se muestran tras `onBlur`). */
type TouchedFields = Partial<Record<CredentialField, boolean>>;

const INITIAL_VALUES: LoginFormValues = {
  identifier: "",
  password: "",
  rememberSession: false,
};

/** Mensaje que se muestra en el formulario. */
export interface FormMessage {
  type: "error" | "info";
  text: string;
}

export interface UseLoginFormResult {
  values: LoginFormValues;
  errors: CredentialErrors;
  isSubmitting: boolean;
  message: FormMessage | null;
  setMessage: (message: FormMessage | null) => void;
  setFieldValue: (field: CredentialField, value: string) => void;
  setRememberSession: (remember: boolean) => void;
  handleBlur: (field: CredentialField) => void;
  handleSubmit: (event: FormEvent<HTMLFormElement>) => Promise<void>;
}

export function useLoginForm(
  loginUseCase: LoginUseCase,
  onAuthenticated: (session: AuthSession) => void,
  validationMessages: CredentialValidationMessages = DEFAULT_CREDENTIAL_VALIDATION_MESSAGES,
): UseLoginFormResult {
  const [values, setValues] = useState<LoginFormValues>(INITIAL_VALUES);
  const [errors, setErrors] = useState<CredentialErrors>({});
  const [touched, setTouched] = useState<TouchedFields>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState<FormMessage | null>(null);

  const setFieldValue = (field: CredentialField, value: string) => {
    const nextValues = { ...values, [field]: value };
    setValues(nextValues);
    // Si el campo ya se validó, se revalida mientras se corrige.
    if (touched[field]) {
      setErrors((prev) => ({
        ...prev,
        [field]: validateCredentialField(field, nextValues, validationMessages),
      }));
    }
  };

  const setRememberSession = (remember: boolean) => {
    setValues((prev) => ({ ...prev, rememberSession: remember }));
  };

  const handleBlur = (field: CredentialField) => {
    setTouched((prev) => ({ ...prev, [field]: true }));
    setErrors((prev) => ({
      ...prev,
      [field]: validateCredentialField(field, values, validationMessages),
    }));
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (isSubmitting) return;

    setTouched({ identifier: true, password: true });
    setErrors({});
    setMessage(null);
    setIsSubmitting(true);

    const result = await loginUseCase.execute({
      credentials: { identifier: values.identifier, password: values.password },
      rememberSession: values.rememberSession,
    });

    switch (result.status) {
      case "success":
        // Al iniciar sesión se cambia a la app, así que no hace falta mensaje.
        onAuthenticated(result.session);
        return;
      case "invalid-input":
        setErrors(validateCredentials(values, validationMessages));
        setMessage({ type: "error", text: "Por favor, corrige los errores en el formulario" });
        break;
      case "invalid-credentials":
        setMessage({ type: "error", text: "Credenciales incorrectas. Verifica tu usuario y contraseña" });
        break;
      case "service-error":
        setMessage({ type: "error", text: "No se pudo conectar con el servidor. Inténtalo de nuevo" });
        break;
    }
    setIsSubmitting(false);
  };

  return {
    values,
    errors,
    isSubmitting,
    message,
    setMessage,
    setFieldValue,
    setRememberSession,
    handleBlur,
    handleSubmit,
  };
}
