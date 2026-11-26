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
  Active: "bg-sky-600",
  Closed: "bg-emerald-500",
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
    return (
      <p className="rounded-2xl border border-slate-200 bg-white/80 px-5 py-8 text-center text-sm text-slate-500">
        No hay sprints configurados.
      </p>
    );
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
      <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-slate-200/80 bg-white/90 p-4 text-xs shadow-md shadow-sky-100/50">
        <div className="flex flex-wrap items-center gap-3">
          <select
            value={activeSprint.id}
            onChange={(e) => onSelectSprint(Number(e.target.value))}
            className="rounded-xl border border-slate-200 bg-white px-3 py-2 font-medium text-slate-800 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
          >
            {sprints.map((sprint) => (
              <option key={sprint.id} value={sprint.id}>
                {sprint.name}
              </option>
            ))}
          </select>

          <span className="text-slate-500">
            {activeSprint.startDate} to {activeSprint.endDate}
          </span>
        </div>

        <div className="flex items-center gap-3">
          <span className="text-slate-500">
            Completed:{" "}
            <strong className="text-slate-800">
              {closedCount}/{totalCount}
            </strong>{" "}
            ({completionPct}%)
          </span>
          <div className="h-2.5 w-28 overflow-hidden rounded-full bg-slate-100">
            <div
              className={`h-full ${completionPct === 100 ? "bg-emerald-500" : "bg-sky-600"}`}
              style={{ width: `${completionPct}%` }}
            />
          </div>
        </div>
      </div>

      <div className="flex flex-wrap items-center gap-2 text-xs">
        <select
          value={selectedToAdd}
          onChange={(e) => setSelectedToAdd(e.target.value)}
          className="min-w-64 rounded-xl border border-slate-200 bg-white px-3 py-2 text-slate-700 outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
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
          className="cursor-pointer rounded-lg bg-sky-600 px-3.5 py-2 font-semibold text-white shadow-sm shadow-sky-600/20 transition hover:bg-sky-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500/40 disabled:cursor-not-allowed disabled:opacity-50"
        >
          Add to Sprint
        </button>
      </div>

      <div className="overflow-x-auto rounded-2xl border border-slate-200/80 bg-white/90 p-4 shadow-lg shadow-sky-100/60">
        <table className="w-full min-w-[640px] border-collapse text-left text-xs">
          <thead>
            <tr className="border-b border-slate-200 text-slate-500">
              <th className="w-14 py-3 font-medium">ID</th>
              <th className="w-24 py-3 font-medium">Tipo</th>
              <th className="py-3 font-medium">Título</th>
              <th className="w-28 py-3 font-medium">Estado</th>
              <th className="w-36 py-3 text-right font-medium">Acciones</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {sprintItems.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-8 text-center text-slate-500">
                  No hay elementos asignados a este sprint.
                </td>
              </tr>
            ) : (
              sprintItems.map((item) => (
                <tr key={item.id} className="transition-colors hover:bg-sky-50/70">
                  <td className="py-3 text-slate-500">#{item.id}</td>
                  <td className="py-3">
                    <span className="inline-flex items-center gap-1.5">
                      <span className={typeBadge[item.type].color}>
                        {typeBadge[item.type].label}
                      </span>
                      <span>{item.type}</span>
                    </span>
                  </td>
                  <td className="py-3 text-slate-700">{item.title}</td>
                  <td className="py-3">
                    <div className="flex items-center gap-2">
                      <span
                        className={`h-2 w-2 rounded-full ${stateDot[item.state]}`}
                      />
                      <span>{item.state}</span>
                    </div>
                  </td>
                  <td className="space-x-2 py-3 text-right">
                    <button
                      type="button"
                      onClick={() => onRemoveItemFromSprint(item.id)}
                      className="cursor-pointer rounded-lg px-2.5 py-1 text-[11px] font-medium text-slate-600 transition hover:bg-sky-50 hover:text-sky-800"
                    >
                      Quitar
                    </button>
                    <button
                      type="button"
                      onClick={() => onRequestDelete(item)}
                      className="cursor-pointer rounded-lg px-2.5 py-1 text-[11px] font-medium text-slate-400 transition hover:bg-red-50 hover:text-red-600"
                    >
                      Eliminar
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
