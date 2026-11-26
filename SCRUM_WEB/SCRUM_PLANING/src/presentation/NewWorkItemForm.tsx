import { type FormEvent, useState } from "react";
import type { WorkItemState, WorkItemType } from "../domain/backlog";
import type { CreateWorkItemInput } from "../infrastructure/backlogApi";

interface NewWorkItemFormProps {
  onSubmit: (input: CreateWorkItemInput) => void;
  onCancel: () => void;
  isSubmitting: boolean;
}

const levelByType: Record<WorkItemType, number> = {
  Epic: 0,
  Feature: 1,
  Story: 2,
  Task: 3,
};

export function NewWorkItemForm({
  onSubmit,
  onCancel,
  isSubmitting,
}: NewWorkItemFormProps) {
  const [type, setType] = useState<WorkItemType>("Story");
  const [title, setTitle] = useState("");
  const [state, setState] = useState<WorkItemState>("New");

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    const trimmed = title.trim();
    if (!trimmed) return;

    onSubmit({
      type,
      title: trimmed,
      state,
      level: levelByType[type],
    });
    setTitle("");
  };

  return (
    <form
      onSubmit={handleSubmit}
      className="mb-4 flex flex-wrap items-center gap-2 rounded-2xl border border-sky-100 bg-white/90 p-4 text-xs shadow-md shadow-sky-100/50"
    >
      <select
        value={type}
        onChange={(e) => setType(e.target.value as WorkItemType)}
        className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-slate-700 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
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
        placeholder="Enter work item title..."
        autoFocus
        className="min-w-64 flex-1 rounded-xl border border-slate-200 bg-white px-3 py-2 text-slate-900 outline-none placeholder:text-slate-400 focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
      />

      <select
        value={state}
        onChange={(e) => setState(e.target.value as WorkItemState)}
        className="rounded-xl border border-slate-200 bg-white px-3 py-2 text-slate-700 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
      >
        <option value="New">New</option>
        <option value="Active">Active</option>
        <option value="Closed">Closed</option>
      </select>

      <button
        type="submit"
        disabled={isSubmitting}
        className="cursor-pointer rounded-lg bg-sky-600 px-3.5 py-2 font-semibold text-white shadow-sm shadow-sky-600/20 transition hover:bg-sky-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500/40 disabled:cursor-not-allowed disabled:opacity-50"
      >
        {isSubmitting ? "Saving..." : "Add"}
      </button>

      <button
        type="button"
        onClick={onCancel}
        className="cursor-pointer rounded-lg px-3 py-2 font-medium text-slate-600 transition hover:bg-sky-50 hover:text-sky-800"
      >
        Cancel
      </button>
    </form>
  );
}
