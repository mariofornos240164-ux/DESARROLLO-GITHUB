import { type FormEvent, useState } from "react";
import type {
  WorkItemParentOptions,
  WorkItemState,
  WorkItemType,
} from "../domain/backlog";
import type { CreateWorkItemInput } from "../infrastructure/backlogApi";

interface NewWorkItemFormProps {
  onSubmit: (input: CreateWorkItemInput) => void;
  onCancel: () => void;
  isSubmitting: boolean;
  parents: WorkItemParentOptions;
  isLoadingParents: boolean;
  initialType?: WorkItemType;
  error?: string;
  parentError?: string | null;
}

const parentTypeLabels: Record<WorkItemType, string> = {
  Epic: "iniciativas",
  Feature: "Epics",
  Story: "Features",
  Task: "Stories",
};

const itemTypeLabels: Record<WorkItemType, string> = {
  Epic: "Epic",
  Feature: "Feature",
  Story: "Story",
  Task: "Task",
};

export function NewWorkItemForm({
  onSubmit,
  onCancel,
  isSubmitting,
  parents,
  isLoadingParents,
  initialType = "Epic",
  error,
  parentError,
}: NewWorkItemFormProps) {
  const [type, setType] = useState<WorkItemType>(initialType);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [acceptanceCriteria, setAcceptanceCriteria] = useState("");
  const [state, setState] = useState<WorkItemState>("New");
  const parentOptions = parents[type] ?? [];
  const [selectedParentIds, setSelectedParentIds] = useState<
    Partial<Record<WorkItemType, string>>
  >({});
  const parentId =
    parentOptions.find((parent) => parent.id === selectedParentIds[type])?.id ??
    parentOptions[0]?.id ??
    "";

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const trimmedTitle = title.trim();
    const trimmedDescription = description.trim();
    if (!trimmedTitle || !trimmedDescription || !parentId) return;

    onSubmit({
      type,
      title: trimmedTitle,
      description: trimmedDescription,
      ...(type === "Feature" || type === "Story"
        ? { acceptanceCriteria: acceptanceCriteria.trim() }
        : {}),
      state,
      parentId,
    });
  };

  return (
    <form
      onSubmit={handleSubmit}
      className="mb-4 grid grid-cols-1 gap-3 rounded-2xl border border-sky-100 bg-white/90 p-4 text-xs shadow-md shadow-sky-100/50 sm:grid-cols-2 lg:grid-cols-4"
    >
      {(error || parentError) && (
        <p
          role="alert"
          className="rounded-lg border border-red-100 bg-red-50 px-3 py-2 text-red-700 sm:col-span-2 lg:col-span-4"
        >
          {error ?? parentError}
        </p>
      )}
      <select
        value={type}
        onChange={(e) => setType(e.target.value as WorkItemType)}
        aria-label="Tipo de elemento"
        className="min-w-0 rounded-xl border border-slate-200 bg-white px-3 py-2 text-slate-700 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
      >
        <option value="Epic">Epic</option>
        <option value="Feature">Feature</option>
        <option value="Story">Story</option>
        <option value="Task">Task</option>
      </select>

      <input
        type="text"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        placeholder="Título"
        maxLength={type === "Epic" ? 100 : 500}
        required
        autoFocus
        className="min-w-0 rounded-xl border border-slate-200 bg-white px-3 py-2 text-slate-900 outline-none placeholder:text-slate-400 focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
      />

      <select
        value={parentId}
        onChange={(e) =>
          setSelectedParentIds((previous) => ({
            ...previous,
            [type]: e.target.value,
          }))
        }
        aria-label="Elemento padre"
        required
        disabled={isLoadingParents || parentOptions.length === 0}
        className="min-w-0 rounded-xl border border-slate-200 bg-white px-3 py-2 text-slate-700 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20 disabled:bg-slate-50"
      >
        {isLoadingParents ? (
          <option value="">Cargando elementos padre...</option>
        ) : parentOptions.length === 0 ? (
          <option value="">No hay {parentTypeLabels[type]} disponibles</option>
        ) : (
          parentOptions.map((parent) => (
            <option key={parent.id} value={parent.id}>
              {parent.title}
            </option>
          ))
        )}
      </select>

      <select
        value={state}
        onChange={(e) => setState(e.target.value as WorkItemState)}
        aria-label="Estado"
        className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-slate-700 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
      >
        <option value="New">New</option>
        <option value="Active">Active</option>
        <option value="Closed">Closed</option>
      </select>

      <textarea
        value={description}
        onChange={(e) => setDescription(e.target.value)}
        placeholder="Descripción"
        maxLength={2000}
        required
        rows={2}
        className="resize-y rounded-xl border border-slate-200 bg-white px-3 py-2 text-slate-900 outline-none placeholder:text-slate-400 focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20 sm:col-span-2 lg:col-span-4"
      />

      {(type === "Feature" || type === "Story") && (
        <textarea
          value={acceptanceCriteria}
          onChange={(e) => setAcceptanceCriteria(e.target.value)}
          placeholder="Criterios de aceptación"
          maxLength={4000}
          required
          rows={2}
          className="resize-y rounded-xl border border-slate-200 bg-white px-3 py-2 text-slate-900 outline-none placeholder:text-slate-400 focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20 sm:col-span-2 lg:col-span-4"
        />
      )}

      {isLoadingParents && !parentError && (
        <p className="text-slate-500 sm:col-span-2 lg:col-span-4">
          Consultando las opciones para crear {itemTypeLabels[type]}...
        </p>
      )}

      {!isLoadingParents && !parentError && parentOptions.length === 0 && (
        <p className="text-amber-700 sm:col-span-2 lg:col-span-4">
          No hay {parentTypeLabels[type]} disponibles. Para crear{" "}
          {itemTypeLabels[type]}, primero agrega al menos uno.
        </p>
      )}

      <button
        type="submit"
        disabled={
          isSubmitting || isLoadingParents || parentOptions.length === 0
        }
        className="cursor-pointer rounded-lg bg-sky-600 px-3.5 py-2 font-semibold text-white shadow-sm shadow-sky-600/20 transition hover:bg-sky-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500/40 disabled:cursor-not-allowed disabled:opacity-50"
      >
        {isSubmitting ? "Guardando..." : "Agregar"}
      </button>

      <button
        type="button"
        onClick={onCancel}
        className="cursor-pointer rounded-lg px-3 py-2 font-medium text-slate-600 transition hover:bg-sky-50 hover:text-sky-800"
      >
        Cancelar
      </button>
    </form>
  );
}
