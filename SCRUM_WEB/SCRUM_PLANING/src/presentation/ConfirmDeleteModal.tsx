import type { WorkItem } from "../domain/backlog";

interface ConfirmDeleteModalProps {
  item: WorkItem | null;
  onConfirm: () => void;
  onCancel: () => void;
  isDeleting: boolean;
  error?: string | null;
}

export function ConfirmDeleteModal({
  item,
  onConfirm,
  onCancel,
  isDeleting,
  error,
}: ConfirmDeleteModalProps) {
  if (!item) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/30 p-4 backdrop-blur-sm">
      <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 text-sm shadow-2xl shadow-slate-900/20">
        <h2 className="mb-2 text-base font-semibold text-slate-900">
          Confirmar eliminación
        </h2>
        <p className="mb-5 leading-6 text-slate-600">
          ¿Seguro que quieres eliminar{" "}
          <span className="font-medium text-slate-900">
            #{item.id} - {item.title}
          </span>
          ? Esta acción no se puede deshacer.
        </p>

        {error && (
          <p
            role="alert"
            className="mb-4 rounded-lg border border-red-100 bg-red-50 px-3 py-2 text-red-700"
          >
            {error}
          </p>
        )}

        <div className="flex justify-end gap-2">
          <button
            type="button"
            onClick={onCancel}
            disabled={isDeleting}
            className="cursor-pointer rounded-lg border border-slate-200 bg-white px-3.5 py-2 font-semibold text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
          >
            Cancelar
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={isDeleting}
            className="cursor-pointer rounded-lg bg-red-600 px-3.5 py-2 font-semibold text-white transition hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isDeleting ? "Eliminando..." : "Eliminar"}
          </button>
        </div>
      </div>
    </div>
  );
}
