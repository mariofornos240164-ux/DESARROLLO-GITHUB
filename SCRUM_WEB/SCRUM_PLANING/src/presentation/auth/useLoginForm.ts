import { type FormEvent, useState } from "react";
import { toast } from "sonner";
import type { LoginUseCase } from "../../application/auth/LoginUseCase";
import type { AuthSession } from "../../domain/auth/entities";
import {
  type CredentialErrors,
  type CredentialField,
  validateCredentialField,
} from "../../domain/auth/loginValidation";

// Hook de la vista: maneja el estado del formulario y los toasts.
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

export interface UseLoginFormResult {
  values: LoginFormValues;
  errors: CredentialErrors;
  isSubmitting: boolean;
  setFieldValue: (field: CredentialField, value: string) => void;
  setRememberSession: (remember: boolean) => void;
  handleBlur: (field: CredentialField) => void;
  handleSubmit: (event: FormEvent<HTMLFormElement>) => Promise<void>;
}

export function useLoginForm(
  loginUseCase: LoginUseCase,
  onAuthenticated: (session: AuthSession) => void,
): UseLoginFormResult {
  const [values, setValues] = useState<LoginFormValues>(INITIAL_VALUES);
  const [errors, setErrors] = useState<CredentialErrors>({});
  const [touched, setTouched] = useState<TouchedFields>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const setFieldValue = (field: CredentialField, value: string) => {
    const nextValues = { ...values, [field]: value };
    setValues(nextValues);
    // Si el campo ya se validó, se revalida mientras se corrige.
    if (touched[field]) {
      setErrors((prev) => ({
        ...prev,
        [field]: validateCredentialField(field, nextValues),
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
      [field]: validateCredentialField(field, values),
    }));
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (isSubmitting) return;

    setTouched({ identifier: true, password: true });
    setErrors({});
    setIsSubmitting(true);

    const result = await loginUseCase.execute({
      credentials: { identifier: values.identifier, password: values.password },
      rememberSession: values.rememberSession,
    });

    switch (result.status) {
      case "success":
        toast.success("¡Bienvenido! Sesión iniciada correctamente");
        onAuthenticated(result.session);
        return;
      case "invalid-input":
        setErrors(result.errors);
        toast.error("Por favor, corrige los errores en el formulario");
        break;
      case "invalid-credentials":
        toast.error("Credenciales incorrectas. Verifica tu usuario y contraseña");
        break;
      case "service-error":
        toast.error("No se pudo conectar con el servidor. Inténtalo de nuevo");
        break;
    }
    setIsSubmitting(false);
  };

  return {
    values,
    errors,
    isSubmitting,
    setFieldValue,
    setRememberSession,
    handleBlur,
    handleSubmit,
  };
}
