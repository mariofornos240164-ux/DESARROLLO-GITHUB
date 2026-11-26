import type { WorkItem, WorkItemState } from "../domain/backlog";

const states: WorkItemState[] = ["New", "Active", "Closed"];

interface WorkItemsBoardProps {
  items: WorkItem[];
  visibleStates: WorkItemState[];
  onRequestDelete: (item: WorkItem) => void;
}

export function WorkItemsBoard({
  items,
  visibleStates,
  onRequestDelete,
}: WorkItemsBoardProps) {
  const visibleColumns = states.filter((state) => visibleStates.includes(state));

  if (visibleColumns.length === 0) {
    return (
      <p className="rounded-2xl border border-slate-200 bg-white/90 p-6 text-sm text-slate-500">
        Activa al menos una columna desde las opciones de columna.
      </p>
    );
  }

  return (
    <div className="grid min-w-0 gap-4 md:grid-cols-2 2xl:grid-cols-3">
      {visibleColumns.map((state) => {
        const stateItems = items.filter((item) => item.state === state);
        return (
          <section
            key={state}
            aria-label={`Elementos ${state}`}
            className="min-w-0 rounded-2xl border border-slate-200/80 bg-slate-50 p-3"
          >
            <header className="mb-3 flex items-center justify-between border-b border-slate-200 pb-2 text-sm font-semibold text-slate-800">
              <h2>{state}</h2>
              <span className="rounded-full bg-white px-2 py-0.5 text-xs text-slate-500">
                {stateItems.length}
              </span>
            </header>
            <div className="space-y-2">
              {stateItems.map((item) => (
                <article
                  key={item.id}
                  className="rounded-xl border border-slate-200 bg-white p-3 shadow-sm"
                >
                  <div className="flex items-start justify-between gap-2">
                    <p className="min-w-0 break-words font-medium text-slate-800">
                      {item.title}
                    </p>
                    <span className="shrink-0 rounded bg-sky-50 px-2 py-1 text-[10px] font-medium text-sky-800">
                      {item.type}
                    </span>
                  </div>
                  <div className="mt-3 flex items-center justify-between gap-2 text-[11px] text-slate-500">
                    <span className="min-w-0 truncate">#{item.id}</span>
                    <button
                      type="button"
                      onClick={() => onRequestDelete(item)}
                      aria-label={`Eliminar ${item.title}`}
                      className="shrink-0 cursor-pointer rounded px-2 py-1 font-medium text-slate-500 transition hover:bg-red-50 hover:text-red-600"
                    >
                      Eliminar
                    </button>
                  </div>
                </article>
              ))}
              {stateItems.length === 0 && (
                <p className="rounded-xl border border-dashed border-slate-200 px-3 py-5 text-center text-xs text-slate-500">
                  Sin elementos
                </p>
              )}
            </div>
          </section>
        );
      })}
    </div>
  );
}
