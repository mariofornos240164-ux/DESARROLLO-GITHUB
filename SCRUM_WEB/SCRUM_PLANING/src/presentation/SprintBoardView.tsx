import { useState } from "react";
import type {
  Sprint,
  WorkItem,
  WorkItemState,
  WorkItemType,
} from "../domain/backlog";

const typeBadge: Record<WorkItemType, { label: string; color: string }> = {
  Epic: { label: "♛", color: "text-orange-500" },
  Feature: { label: "🏆", color: "text-purple-600" },
  Story: { label: "📘", color: "text-sky-600" },
  Task: { label: "☑", color: "text-amber-500" },
};

const stateDot: Record<WorkItemState, string> = {
  New: "bg-gray-400",
  Active: "bg-blue-600",
  Closed: "bg-green-600",
};

interface SprintBoardViewProps {
  sprints: Sprint[];
  activeSprint: Sprint | null;
  onSelectSprint: (sprintId: number) => void;
  sprintItems: WorkItem[];
  availableItems: WorkItem[];
  onAddItemToSprint: (workItemId: number) => void;
  onRemoveItemFromSprint: (workItemId: number) => void;
  onRequestDelete: (item: WorkItem) => void;
}

export function SprintBoardView({
  sprints,
  activeSprint,
  onSelectSprint,
  sprintItems,
  availableItems,
  onAddItemToSprint,
  onRemoveItemFromSprint,
  onRequestDelete,
}: SprintBoardViewProps) {
  const [selectedToAdd, setSelectedToAdd] = useState<string>("");

  if (!activeSprint) {
    return <p className="py-6 text-xs text-gray-500">No sprints configured.</p>;
  }

  const totalCount = sprintItems.length;
  const closedCount = sprintItems.filter(
    (item) => item.state === "Closed",
  ).length;
  const completionPct =
    totalCount > 0 ? Math.round((closedCount / totalCount) * 100) : 0;

  const handleAdd = () => {
    const id = Number(selectedToAdd);
    if (!id) return;
    onAddItemToSprint(id);
    setSelectedToAdd("");
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3 rounded border border-gray-200 bg-gray-50/70 p-3 text-xs">
        <div className="flex flex-wrap items-center gap-3">
          <select
            value={activeSprint.id}
            onChange={(e) => onSelectSprint(Number(e.target.value))}
            className="rounded border border-gray-300 bg-white px-2.5 py-1.5 font-medium text-gray-900"
          >
            {sprints.map((sprint) => (
              <option key={sprint.id} value={sprint.id}>
                {sprint.name}
              </option>
            ))}
          </select>

          <span className="text-gray-600">
            {activeSprint.startDate} to {activeSprint.endDate}
          </span>
        </div>

        <div className="flex items-center gap-3">
          <span className="text-gray-600">
            Completed:{" "}
            <strong className="text-gray-900">
              {closedCount}/{totalCount}
            </strong>{" "}
            ({completionPct}%)
          </span>
          <div className="h-3 w-28 overflow-hidden bg-gray-200">
            <div
              className={`h-full ${completionPct === 100 ? "bg-green-700" : "bg-blue-600"}`}
              style={{ width: `${completionPct}%` }}
            />
          </div>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-2 text-xs">
        <select
          value={selectedToAdd}
          onChange={(e) => setSelectedToAdd(e.target.value)}
          className="rounded border border-gray-300 bg-white px-2.5 py-1.5 text-gray-800"
        >
          <option value="">Assign work item to {activeSprint.name}...</option>
          {availableItems.map((item) => (
            <option key={item.id} value={item.id}>
              #{item.id} [{item.type}] {item.title}
            </option>
          ))}
        </select>

        <button
          type="button"
          onClick={handleAdd}
          disabled={!selectedToAdd}
          className="cursor-pointer rounded bg-blue-600 px-3 py-1.5 font-medium text-white hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
        >
          Add to Sprint
        </button>
      </div>

      <table className="w-full border-collapse text-left text-xs">
        <thead>
          <tr className="border-b border-gray-200 text-gray-500">
            <th className="w-14 py-2 font-medium">ID</th>
            <th className="w-24 py-2 font-medium">Type</th>
            <th className="py-2 font-medium">Title</th>
            <th className="w-28 py-2 font-medium">State</th>
            <th className="w-36 py-2 text-right font-medium">Actions</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {sprintItems.length === 0 ? (
            <tr>
              <td colSpan={5} className="py-6 text-center text-gray-500">
                No work items assigned to this sprint.
              </td>
            </tr>
          ) : (
            sprintItems.map((item) => (
              <tr key={item.id} className="hover:bg-blue-50/40">
                <td className="py-2 text-gray-500">#{item.id}</td>
                <td className="py-2">
                  <span className="inline-flex items-center gap-1.5">
                    <span className={typeBadge[item.type].color}>
                      {typeBadge[item.type].label}
                    </span>
                    <span>{item.type}</span>
                  </span>
                </td>
                <td className="py-2 text-gray-800">{item.title}</td>
                <td className="py-2">
                  <div className="flex items-center gap-2">
                    <span
                      className={`h-2 w-2 rounded-full ${stateDot[item.state]}`}
                    />
                    <span>{item.state}</span>
                  </div>
                </td>
                <td className="space-x-2 py-2 text-right">
                  <button
                    type="button"
                    onClick={() => onRemoveItemFromSprint(item.id)}
                    className="cursor-pointer rounded px-2 py-0.5 text-[11px] text-gray-600 hover:bg-gray-100 hover:text-gray-900"
                  >
                    Unassign
                  </button>
                  <button
                    type="button"
                    onClick={() => onRequestDelete(item)}
                    className="cursor-pointer rounded px-2 py-0.5 text-[11px] text-gray-400 hover:bg-red-50 hover:text-red-600"
                  >
                    Delete
                  </button>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </div>
  );
}
