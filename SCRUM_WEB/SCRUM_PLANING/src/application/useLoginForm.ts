import { type FormEvent, useState } from "react";
import { toast } from "sonner";
import {
  type AuthSession,
  InvalidCredentialsError,
  type LoginField,
  type LoginFormErrors,
  type LoginFormValues,
  type LoginTouchedFields,
} from "../domain/auth";
import { login, saveSession } from "../infrastructure/authApi";
import {
  hasErrors,
  validateLoginField,
  validateLoginForm,
} from "./loginValidation";

const INITIAL_VALUES: LoginFormValues = {
  identifier: "",
  password: "",
  rememberSession: false,
};

export interface UseLoginFormResult {
  values: LoginFormValues;
  errors: LoginFormErrors;
  isSubmitting: boolean;
  setFieldValue: (field: LoginField, value: string) => void;
  setRememberSession: (remember: boolean) => void;
  handleBlur: (field: LoginField) => void;
  handleSubmit: (event: FormEvent<HTMLFormElement>) => Promise<void>;
}

export function useLoginForm(
  onAuthenticated: (session: AuthSession) => void,
): UseLoginFormResult {
  const [values, setValues] = useState<LoginFormValues>(INITIAL_VALUES);
  const [errors, setErrors] = useState<LoginFormErrors>({});
  const [touched, setTouched] = useState<LoginTouchedFields>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  const setFieldValue = (field: LoginField, value: string) => {
    const nextValues = { ...values, [field]: value };
    setValues(nextValues);
    // Si el campo ya mostró un error, se revalida mientras se corrige.
    if (touched[field]) {
      setErrors((prev) => ({
        ...prev,
        [field]: validateLoginField(field, nextValues),
      }));
    }
  };

  const setRememberSession = (remember: boolean) => {
    setValues((prev) => ({ ...prev, rememberSession: remember }));
  };

  const handleBlur = (field: LoginField) => {
    setTouched((prev) => ({ ...prev, [field]: true }));
    setErrors((prev) => ({
      ...prev,
      [field]: validateLoginField(field, values),
    }));
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (isSubmitting) return;

    const nextErrors = validateLoginForm(values);
    setErrors(nextErrors);
    setTouched({ identifier: true, password: true });

    if (hasErrors(nextErrors)) {
      toast.error("Por favor, corrige los errores en el formulario");
      return;
    }

    setIsSubmitting(true);
    try {
      const session = await login({
        identifier: values.identifier.trim(),
        password: values.password,
      });
      saveSession(session, values.rememberSession);
      toast.success("¡Bienvenido! Sesión iniciada correctamente");
      onAuthenticated(session);
    } catch (error) {
      if (error instanceof InvalidCredentialsError) {
        toast.error("Credenciales incorrectas. Verifica tu usuario y contraseña");
      } else {
        toast.error("No se pudo conectar con el servidor. Inténtalo de nuevo");
      }
      setIsSubmitting(false);
    }
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
