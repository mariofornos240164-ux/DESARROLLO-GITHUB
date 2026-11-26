import { useBacklog } from "./application/useBacklog";
import type { ActiveSection, BacklogLevelFilter } from "./domain/backlog";
import { BacklogRow } from "./presentation/BacklogRow";
import { ConfirmDeleteModal } from "./presentation/ConfirmDeleteModal";
import { NewWorkItemForm } from "./presentation/NewWorkItemForm";
import { SprintBoardView } from "./presentation/SprintBoardView";
import { WorkItemsTable } from "./presentation/WorkItemsTable";

interface AppProps {
  userName?: string;
  onLogout?: () => void;
}

export default function App({ userName, onLogout }: AppProps) {
  const {
    activeSection,
    setActiveSection,
    visibleItems,
    flatItems,
    isLoading,
    isError,
    search,
    setSearch,
    selectedLevel,
    setSelectedLevel,
    collapsedIds,
    toggleCollapse,
    isCreating,
    setIsCreating,
    createWorkItem,
    isCreatingPending,
    itemToDelete,
    requestDeleteItem,
    cancelDeleteItem,
    confirmDeleteItem,
    isDeletingPending,
    sprints,
    activeSprint,
    setSelectedSprintId,
    sprintItems,
    availableForSprint,
    toggleItemInSprint,
  } = useBacklog();

  const isBacklogsView = activeSection === "Backlogs";

  return (
    <div className="flex min-h-screen w-full flex-col bg-linear-to-br from-sky-50 via-white to-blue-50 text-sm text-slate-700">
      <header className="sticky top-0 z-30 flex min-h-16 flex-wrap items-center justify-between gap-3 border-b border-sky-100 bg-white/85 px-4 py-3 shadow-sm backdrop-blur-sm sm:px-6">
        <div className="flex items-center gap-3">
          <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-linear-to-br from-sky-600 to-blue-600 text-xs font-bold text-white shadow-md shadow-sky-600/20">
            SP
          </span>
          <div>
            <p className="font-semibold tracking-tight text-slate-900">
              Scrum Planning
            </p>
            <div className="flex flex-wrap items-center gap-1.5 text-xs text-slate-500">
              <span>Design Agile</span>
              <span aria-hidden="true">/</span>
              <span>Boards</span>
              <span aria-hidden="true">/</span>
              <span className="font-medium text-sky-700">{activeSection}</span>
            </div>
          </div>
        </div>

        <div className="flex min-w-0 flex-1 flex-wrap items-center justify-end gap-3">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Buscar elementos..."
            aria-label="Buscar elementos de trabajo"
            className="w-full min-w-48 max-w-xs rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2 text-xs text-slate-800 outline-none transition placeholder:text-slate-400 focus:border-sky-400 focus:bg-white focus:ring-2 focus:ring-sky-500/20"
          />

          {onLogout && (
            <div className="flex items-center gap-3 text-xs text-slate-600">
              {userName && (
                <span className="max-w-40 truncate rounded-full bg-sky-50 px-3 py-2 font-medium text-sky-800">
                  {userName}
                </span>
              )}
              <button
                type="button"
                onClick={onLogout}
                className="cursor-pointer rounded-lg border border-sky-100 bg-white px-3 py-2 font-medium text-sky-700 transition hover:border-sky-200 hover:bg-sky-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500/40"
              >
                Cerrar sesión
              </button>
            </div>
          )}
        </div>
      </header>

      <div className="flex flex-1 flex-col lg:flex-row">
        <aside className="w-full border-b border-sky-100 bg-white/65 p-3 lg:w-56 lg:border-b-0 lg:border-r lg:p-4">
          <div className="mb-4 flex items-center gap-2 px-2 py-1.5 font-semibold text-slate-900">
            <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-linear-to-br from-sky-600 to-blue-600 text-xs text-white shadow-sm">
              DA
            </span>
            <span>Design Agile</span>
          </div>

          <nav className="space-y-0.5 text-xs">
            {[
              "Overview",
              "Boards",
              "Work Items",
              "Backlogs",
              "Sprints",
              "Queries",
            ].map((menu) => {
              const isSelectable =
                menu === "Backlogs" ||
                menu === "Work Items" ||
                menu === "Sprints";
              const isActive = activeSection === menu;

              return (
                <button
                  key={menu}
                  type="button"
                  onClick={() => {
                    if (isSelectable) setActiveSection(menu as ActiveSection);
                  }}
                  className={`flex w-full items-center justify-between rounded px-3 py-2 text-left ${
                    isActive
                      ? "bg-sky-100 font-semibold text-sky-800 shadow-sm"
                      : isSelectable
                        ? "cursor-pointer text-slate-600 hover:bg-sky-50 hover:text-sky-800"
                        : "cursor-default text-slate-400"
                  }`}
                >
                  <span>{menu}</span>
                </button>
              );
            })}
          </nav>
        </aside>

        <main className="min-w-0 flex-1 overflow-auto p-4 sm:p-6">
          <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="text-xs font-medium uppercase tracking-wide text-sky-700">
                Espacio de trabajo
              </p>
              <h1 className="mt-1 text-xl font-semibold tracking-tight text-slate-900">
                {activeSection === "Sprints"
                  ? (activeSprint?.name ?? "Sprints")
                  : isBacklogsView
                    ? "Design Agile Team"
                    : "Work Items"}
              </h1>
            </div>

            {isBacklogsView && (
              <select
                value={selectedLevel}
                onChange={(e) =>
                  setSelectedLevel(e.target.value as BacklogLevelFilter)
                }
                aria-label="Filtrar nivel de backlog"
                className="rounded-xl border border-slate-200 bg-white px-3.5 py-2 text-xs font-medium text-slate-700 shadow-sm outline-none transition hover:border-sky-300 focus:border-sky-400 focus:ring-2 focus:ring-sky-500/20"
              >
                <option value="All">Stories and Tasks</option>
                <option value="Features">Features</option>
                <option value="Epics">Epics</option>
              </select>
            )}
          </div>

          <div className="mb-4 flex flex-wrap items-center gap-2 border-b border-sky-100 pb-3 text-xs">
            <button
              type="button"
              onClick={() => setIsCreating((prev) => !prev)}
              className="flex cursor-pointer items-center gap-1.5 rounded-lg bg-sky-600 px-3.5 py-2 font-semibold text-white shadow-sm shadow-sky-600/20 transition hover:bg-sky-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500/40"
            >
              <span aria-hidden="true" className="text-base leading-none">+</span>
              Nuevo elemento
            </button>
            <button
              type="button"
              className="cursor-pointer rounded-lg px-3 py-2 font-medium text-slate-600 transition hover:bg-sky-50 hover:text-sky-800"
            >
              Vista de tablero
            </button>
            <button
              type="button"
              className="cursor-pointer rounded-lg px-3 py-2 font-medium text-slate-600 transition hover:bg-sky-50 hover:text-sky-800"
            >
              Opciones de columna
            </button>
          </div>

          {isCreating && (
            <NewWorkItemForm
              onSubmit={createWorkItem}
              onCancel={() => setIsCreating(false)}
              isSubmitting={isCreatingPending}
            />
          )}

          {isLoading ? (
            <p className="py-6 text-xs text-slate-500">Cargando backlog...</p>
          ) : isError ? (
            <p className="rounded-xl border border-red-100 bg-red-50/80 px-4 py-3 text-xs text-red-700">
              Error al cargar el backlog.
            </p>
          ) : activeSection === "Sprints" ? (
            <SprintBoardView
              sprints={sprints}
              activeSprint={activeSprint}
              onSelectSprint={setSelectedSprintId}
              sprintItems={sprintItems}
              availableItems={availableForSprint}
              onAddItemToSprint={toggleItemInSprint}
              onRemoveItemFromSprint={toggleItemInSprint}
              onRequestDelete={requestDeleteItem}
            />
          ) : isBacklogsView ? (
            <div className="overflow-x-auto rounded-2xl border border-slate-200/80 bg-white/90 p-4 shadow-lg shadow-sky-100/60">
              <table className="w-full min-w-[640px] border-collapse text-left text-xs">
                <thead>
                  <tr className="border-b border-slate-200 text-slate-500">
                    <th className="w-12 py-3 font-medium">Orden</th>
                    <th className="py-3 font-medium">Título</th>
                    <th className="w-28 py-3 font-medium">Estado</th>
                    <th className="w-44 py-3 font-medium">Progreso</th>
                    <th className="w-16 py-3 text-right font-medium"></th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {visibleItems.map((item) => (
                    <BacklogRow
                      key={item.id}
                      item={item}
                      isCollapsed={collapsedIds.has(item.id)}
                      onToggleCollapse={toggleCollapse}
                      onRequestDelete={requestDeleteItem}
                    />
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <WorkItemsTable
              items={flatItems}
              onRequestDelete={requestDeleteItem}
            />
          )}
        </main>
      </div>

      <ConfirmDeleteModal
        item={itemToDelete}
        onConfirm={confirmDeleteItem}
        onCancel={cancelDeleteItem}
        isDeleting={isDeletingPending}
      />
    </div>
  );
}
