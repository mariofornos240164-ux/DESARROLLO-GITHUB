import type { WorkItem, WorkItemState, WorkItemType } from "../domain/backlog";

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
    <tr className="hover:bg-blue-50/40">
      <td className="py-2 text-gray-500">{item.order}</td>

      <td className="py-2">
        <div
          className="flex items-center gap-1.5"
          style={{ paddingLeft: `${item.level * 20}px` }}
        >
          {item.hasChildren ? (
            <button
              type="button"
              onClick={() => onToggleCollapse(item.id)}
              className="w-4 cursor-pointer text-center text-gray-500 hover:text-gray-900"
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
                ? "font-medium text-blue-700 hover:underline"
                : "text-gray-800"
            }
          >
            {item.title}
          </span>
        </div>
      </td>

      <td className="py-2">
        <div className="flex items-center gap-2">
          <span className={`h-2 w-2 rounded-full ${stateDot[item.state]}`} />
          <span>{item.state}</span>
        </div>
      </td>

      <td className="py-2">
        {item.progress !== undefined && (
          <div className="flex items-center gap-2">
            <div className="h-3.5 w-28 overflow-hidden bg-gray-200">
              <div
                className={`h-full ${
                  item.progress === 100 ? "bg-green-700" : "bg-blue-600"
                }`}
                style={{ width: `${item.progress}%` }}
              />
            </div>
            <span className="text-[11px] text-gray-600">{item.progress}%</span>
          </div>
        )}
      </td>

      <td className="py-2 text-right">
        <button
          type="button"
          onClick={() => onRequestDelete(item)}
          className="cursor-pointer rounded px-2 py-0.5 text-[11px] text-gray-400 hover:bg-red-50 hover:text-red-600"
          aria-label={`Eliminar ${item.title}`}
        >
          Delete
        </button>
      </td>
    </tr>
  );
}
