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

interface WorkItemsTableProps {
  items: WorkItem[];
  onRequestDelete: (item: WorkItem) => void;
}

export function WorkItemsTable({
  items,
  onRequestDelete,
}: WorkItemsTableProps) {
  return (
    <table className="w-full border-collapse text-left text-xs">
      <thead>
        <tr className="border-b border-gray-200 text-gray-500">
          <th className="w-14 py-2 font-medium">ID</th>
          <th className="w-24 py-2 font-medium">Type</th>
          <th className="py-2 font-medium">Title</th>
          <th className="w-28 py-2 font-medium">State</th>
          <th className="w-16 py-2 text-right font-medium"></th>
        </tr>
      </thead>
      <tbody className="divide-y divide-gray-100">
        {items.map((item) => (
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
        ))}
      </tbody>
    </table>
  );
}
