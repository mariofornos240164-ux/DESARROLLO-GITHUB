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

interface BacklogRowProps {
  item: WorkItem;
  isCollapsed: boolean;
  onToggleCollapse: (id: number) => void;
  onRequestDelete: (item: WorkItem) => void;
}

export function BacklogRow({
  item,
  isCollapsed,
  onToggleCollapse,
  onRequestDelete,
}: BacklogRowProps) {
  return (
    <tr className="transition-colors hover:bg-sky-50/70">
      <td className="py-3 text-slate-500">{item.order}</td>

      <td className="py-3">
        <div
          className="flex items-center gap-1.5"
          style={{ paddingLeft: `${item.level * 20}px` }}
        >
          {item.hasChildren ? (
            <button
              type="button"
              onClick={() => onToggleCollapse(item.id)}
              className="w-4 cursor-pointer text-center text-slate-400 transition hover:text-sky-700"
              aria-label={
                isCollapsed ? "Expandir elemento" : "Colapsar elemento"
              }
            >
              {isCollapsed ? "›" : "⌄"}
            </button>
          ) : (
            <span className="w-4" />
          )}

          <span className={typeBadge[item.type].color}>
            {typeBadge[item.type].label}
          </span>

          <span
            className={
              item.level === 0
                ? "font-medium text-sky-700 hover:underline"
                : "text-slate-700"
            }
          >
            {item.title}
          </span>
        </div>
      </td>

      <td className="py-3">
        <div className="flex items-center gap-2">
          <span className={`h-2 w-2 rounded-full ${stateDot[item.state]}`} />
          <span>{item.state}</span>
        </div>
      </td>

      <td className="py-3">
        {item.progress !== undefined && (
          <div className="flex items-center gap-2">
            <div className="h-2.5 w-28 overflow-hidden rounded-full bg-slate-100">
              <div
                className={`h-full ${
                  item.progress === 100 ? "bg-emerald-500" : "bg-sky-600"
                }`}
                style={{ width: `${item.progress}%` }}
              />
            </div>
            <span className="text-[11px] text-slate-500">{item.progress}%</span>
          </div>
        )}
      </td>

      <td className="py-3 text-right">
        <button
          type="button"
          onClick={() => onRequestDelete(item)}
          className="cursor-pointer rounded-lg px-2.5 py-1 text-[11px] font-medium text-slate-400 transition hover:bg-red-50 hover:text-red-600"
          aria-label={`Eliminar ${item.title}`}
        >
          Delete
        </button>
      </td>
    </tr>
  );
}
