import type { WorkItem } from "../domain/backlog";

interface ConfirmDeleteModalProps {
  item: WorkItem | null;
  onConfirm: () => void;
  onCancel: () => void;
  isDeleting: boolean;
}

export function ConfirmDeleteModal({
  item,
  onConfirm,
  onCancel,
  isDeleting,
}: ConfirmDeleteModalProps) {
  if (!item) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4">
      <div className="w-full max-w-md rounded border border-gray-200 bg-white p-5 text-xs shadow-lg">
        <h2 className="mb-2 text-sm font-semibold text-gray-900">
          Confirm deletion
        </h2>
        <p className="mb-4 text-gray-600">
          Are you sure you want to delete{" "}
          <span className="font-medium text-gray-900">
            #{item.id} - {item.title}
          </span>
          ? This action cannot be undone.
        </p>

        <div className="flex justify-end gap-2">
          <button
            type="button"
            onClick={onCancel}
            disabled={isDeleting}
            className="cursor-pointer rounded border border-gray-300 bg-white px-3 py-1.5 font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={isDeleting}
            className="cursor-pointer rounded bg-red-600 px-3 py-1.5 font-medium text-white hover:bg-red-700 disabled:opacity-50"
          >
            {isDeleting ? "Deleting..." : "Delete"}
          </button>
        </div>
      </div>
    </div>
  );
}
