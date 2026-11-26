import { type FormEvent, useState } from "react";
import type {
  CreateUserInput,
  RoleRecord,
  UserOperationResponse,
  UserRecord,
} from "../domain/users";

interface UserManagementPageProps {
  users: UserRecord[];
  roles: RoleRecord[];
  isLoading: boolean;
  error: string | null;
  isCreating: boolean;
  onCreate: (input: CreateUserInput) => Promise<UserOperationResponse>;
  onCreated: (message: string) => void;
}

const emptyForm = {
  userFullName: "",
  userName: "",
  userEmail: "",
  userPassword: "",
  userRolId: "",
};

function getErrorMessage(error: unknown): string {
  return error instanceof Error
    ? error.message
    : "No se pudo registrar el usuario.";
}

export function UserManagementPage({
  users,
  roles,
  isLoading,
  error,
  isCreating,
  onCreate,
  onCreated,
}: UserManagementPageProps) {
  const [form, setForm] = useState(emptyForm);
  const [submissionError, setSubmissionError] = useState<string | null>(null);

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmissionError(null);
    try {
      const result = await onCreate({
        userFullName: form.userFullName.trim(),
        userName: form.userName.trim(),
        userEmail: form.userEmail.trim(),
        userPassword: form.userPassword,
        userRolId: Number(form.userRolId),
      });
      setForm(emptyForm);
      onCreated(result.message_user);
    } catch (submitError) {
      setSubmissionError(getErrorMessage(submitError));
    }
  };

  return (
    <div className="space-y-5">
      <section className="rounded-2xl border border-sky-100 bg-white/90 p-5 shadow-lg shadow-sky-100/50 sm:p-6">
        <div className="mb-4">
          <h2 className="text-base font-semibold text-slate-900">
            Registrar usuario
          </h2>
          <p className="mt-1 text-xs leading-5 text-slate-500">
            La contraseña se envía al procedimiento de usuarios de SQL Server,
            que la cifra antes de guardarla.
          </p>
        </div>

        {(error || submissionError) && (
          <p
            role="alert"
            className="mb-4 rounded-lg border border-red-100 bg-red-50 px-3 py-2 text-xs text-red-700"
          >
            {submissionError ?? error}
          </p>
        )}

        <form
          onSubmit={handleSubmit}
          className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3"
        >
          <label className="grid gap-1.5 text-xs font-medium text-slate-600">
            Nombre completo
            <input
              value={form.userFullName}
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  userFullName: event.target.value,
                }))
              }
              autoComplete="name"
              maxLength={80}
              required
              className="min-w-0 rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
            />
          </label>

          <label className="grid gap-1.5 text-xs font-medium text-slate-600">
            Usuario
            <input
              value={form.userName}
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  userName: event.target.value,
                }))
              }
              autoComplete="username"
              maxLength={80}
              required
              className="min-w-0 rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
            />
          </label>

          <label className="grid gap-1.5 text-xs font-medium text-slate-600">
            Correo electrónico
            <input
              type="email"
              value={form.userEmail}
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  userEmail: event.target.value,
                }))
              }
              autoComplete="email"
              maxLength={80}
              required
              className="min-w-0 rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
            />
          </label>

          <label className="grid gap-1.5 text-xs font-medium text-slate-600">
            Contraseña
            <input
              type="password"
              value={form.userPassword}
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  userPassword: event.target.value,
                }))
              }
              autoComplete="new-password"
              maxLength={256}
              required
              className="min-w-0 rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
            />
          </label>

          <label className="grid gap-1.5 text-xs font-medium text-slate-600">
            Rol activo
            <select
              value={form.userRolId}
              onChange={(event) =>
                setForm((current) => ({
                  ...current,
                  userRolId: event.target.value,
                }))
              }
              required
              disabled={isLoading || roles.length === 0}
              className="min-w-0 rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-700 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20 disabled:bg-slate-50"
            >
              <option value="">
                {isLoading ? "Cargando roles..." : "Selecciona un rol"}
              </option>
              {roles.map((role) => (
                <option key={role.rolId} value={role.rolId}>
                  {role.rolName}
                </option>
              ))}
            </select>
          </label>

          {roles.length === 0 && !isLoading && !error && (
            <p className="self-end text-xs text-amber-700 sm:col-span-2 lg:col-span-3">
              No hay roles activos en la base de datos. Activa o crea un rol
              antes de registrar usuarios.
            </p>
          )}

          <button
            type="submit"
            disabled={
              isCreating || isLoading || roles.length === 0 || !form.userRolId
            }
            className="cursor-pointer rounded-lg bg-sky-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm shadow-sky-600/20 transition hover:bg-sky-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500/40 disabled:cursor-not-allowed disabled:opacity-50 sm:col-span-2 lg:col-span-3"
          >
            {isCreating ? "Guardando usuario..." : "Registrar usuario"}
          </button>
        </form>
      </section>

      <section className="rounded-2xl border border-slate-200/80 bg-white/90 p-4 shadow-lg shadow-sky-100/50 sm:p-5">
        <h2 className="mb-3 text-base font-semibold text-slate-900">
          Usuarios registrados
        </h2>
        {isLoading ? (
          <p className="py-4 text-sm text-slate-500">Cargando usuarios...</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[640px] border-collapse text-left text-xs">
              <thead>
                <tr className="border-b border-slate-200 text-slate-500">
                  <th className="py-3 pr-3 font-medium">Nombre</th>
                  <th className="py-3 pr-3 font-medium">Usuario</th>
                  <th className="py-3 pr-3 font-medium">Correo</th>
                  <th className="py-3 pr-3 font-medium">Rol</th>
                  <th className="py-3 font-medium">Estado</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {users.map((user) => (
                  <tr key={user.userId}>
                    <td className="py-3 pr-3 text-slate-800">
                      {user.userFullName}
                    </td>
                    <td className="py-3 pr-3 text-slate-600">
                      {user.userName}
                    </td>
                    <td className="py-3 pr-3 text-slate-600">
                      {user.userEmail}
                    </td>
                    <td className="py-3 pr-3 text-slate-600">
                      {roles.find((role) => role.rolId === user.userRolId)
                        ?.rolName ?? `Rol ${user.userRolId}`}
                    </td>
                    <td className="py-3 text-slate-600">
                      {user.userEnable ? "Activo" : "Inactivo"}
                    </td>
                  </tr>
                ))}
                {users.length === 0 && (
                  <tr>
                    <td
                      colSpan={5}
                      className="py-8 text-center text-slate-500"
                    >
                      No hay usuarios registrados.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </section>
    </div>
  );
}
