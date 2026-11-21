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
      className="mb-3 flex flex-wrap items-center gap-2 rounded border border-blue-200 bg-blue-50/40 p-2.5 text-xs"
    >
      <select
        value={type}
        onChange={(e) => setType(e.target.value as WorkItemType)}
        className="rounded border border-gray-300 bg-white px-2 py-1.5 text-gray-800"
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
        className="min-w-64 flex-1 rounded border border-gray-300 bg-white px-2.5 py-1.5 text-gray-900 focus:border-blue-500 focus:outline-none"
      />

      <select
        value={state}
        onChange={(e) => setState(e.target.value as WorkItemState)}
        className="rounded border border-gray-300 bg-white px-2 py-1.5 text-gray-800"
      >
        <option value="New">New</option>
        <option value="Active">Active</option>
        <option value="Closed">Closed</option>
      </select>

      <button
        type="submit"
        disabled={isSubmitting}
        className="cursor-pointer rounded bg-blue-600 px-3 py-1.5 font-medium text-white hover:bg-blue-700 disabled:opacity-50"
      >
        {isSubmitting ? "Saving..." : "Add"}
      </button>

      <button
        type="button"
        onClick={onCancel}
        className="cursor-pointer rounded px-2.5 py-1.5 text-gray-600 hover:bg-gray-200/70 hover:text-gray-900"
      >
        Cancel
      </button>
    </form>
  );
}
