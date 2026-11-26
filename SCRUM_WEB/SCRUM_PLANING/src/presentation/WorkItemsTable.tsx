import type { WorkItem, WorkItemState, WorkItemType } from "../domain/backlog";

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

interface WorkItemsTableProps {
  items: WorkItem[];
  onRequestDelete: (item: WorkItem) => void;
}

export function WorkItemsTable({
  items,
  onRequestDelete,
}: WorkItemsTableProps) {
  return (
    <div className="overflow-x-auto rounded-2xl border border-slate-200/80 bg-white/90 p-4 shadow-lg shadow-sky-100/60">
      <table className="w-full min-w-[640px] border-collapse text-left text-xs">
        <thead>
          <tr className="border-b border-slate-200 text-slate-500">
            <th className="w-14 py-3 font-medium">ID</th>
            <th className="w-24 py-3 font-medium">Tipo</th>
            <th className="py-3 font-medium">Título</th>
            <th className="w-28 py-3 font-medium">Estado</th>
            <th className="w-16 py-3 text-right font-medium"></th>
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {items.map((item) => (
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
              <td className="py-3 text-right">
                <button
                  type="button"
                  onClick={() => onRequestDelete(item)}
                  className="cursor-pointer rounded-lg px-2.5 py-1 text-[11px] font-medium text-slate-400 transition hover:bg-red-50 hover:text-red-600"
                  aria-label={`Eliminar ${item.title}`}
                >
                  Eliminar
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
