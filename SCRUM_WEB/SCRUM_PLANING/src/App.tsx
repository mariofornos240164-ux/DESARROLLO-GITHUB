import { useCallback, useEffect, useRef, useState } from "react";
import { useBacklog } from "./application/useBacklog";
import { useAppNavigation } from "./application/useAppNavigation";
import { useUsers } from "./application/useUsers";
import type { BacklogLevelFilter } from "./domain/backlog";
import type { WorkItemState } from "./domain/backlog";
import { BacklogRow } from "./presentation/BacklogRow";
import { ColumnOptionsMenu, type ColumnOption } from "./presentation/ColumnOptionsMenu";
import { ConfirmDeleteModal } from "./presentation/ConfirmDeleteModal";
import { ModulePlaceholder } from "./presentation/ModulePlaceholder";
import { NewWorkItemForm } from "./presentation/NewWorkItemForm";
import { SprintBoardView } from "./presentation/SprintBoardView";
import { ThemeToggle } from "./presentation/ThemeToggle";
import { ToastNotification, type ToastMessage } from "./presentation/ToastNotification";
import { UserManagementPage } from "./presentation/UserManagementPage";
import { WorkItemsBoard } from "./presentation/WorkItemsBoard";
import { WorkItemsTable } from "./presentation/WorkItemsTable";

const routes = [
  { path: "/home", label: "Home", content: "home" },
  { path: "/users", label: "Usuarios", content: "users" },
  { path: "/tasks", label: "Tareas", content: "tasks" },
  { path: "/boards", label: "Boards", content: "board" },
  { path: "/work-items", label: "Work Items", content: "work-items" },
  { path: "/backlogs", label: "Backlogs", content: "backlogs" },
  { path: "/sprints", label: "Sprints", content: "sprints" },
] as const;

type TableColumnKey =
  | "order"
  | "id"
  | "type"
  | "title"
  | "state"
  | "progress"
  | "actions";

const backlogColumns: { key: TableColumnKey; label: string }[] = [
  { key: "order", label: "Orden" },
  { key: "title", label: "Título" },
  { key: "state", label: "Estado" },
  { key: "progress", label: "Progreso" },
  { key: "actions", label: "Acciones" },
];

const workItemColumns: { key: TableColumnKey; label: string }[] = [
  { key: "id", label: "ID" },
  { key: "type", label: "Tipo" },
  { key: "title", label: "Título" },
  { key: "state", label: "Estado" },
  { key: "actions", label: "Acciones" },
];

const boardStates: WorkItemState[] = ["New", "Active", "Closed"];

interface AppProps {
  userName?: string;
  onLogout?: () => void;
  isDarkMode: boolean;
  onToggleTheme: () => void;
}

export default function App({
  userName,
  onLogout,
  isDarkMode,
  onToggleTheme,
}: AppProps) {
  const { pathname, navigate } = useAppNavigation();
  const currentRoute =
    routes.find((route) => route.path === pathname) ??
    { path: pathname, label: "Página no encontrada", content: "not-found" as const };
  const isUsersView = currentRoute.content === "users";
  const {
    visibleItems,
    flatItems,
    isLoading,
    isError,
    loadError,
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
    parentOptions,
    isParentOptionsLoading,
    parentOptionsError,
    mutationError,
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
  const {
    users,
    roles,
    isLoading: isUsersLoading,
    error: usersError,
    createUser,
    isCreating: isUserCreating,
  } = useUsers(isUsersView);

  const isBacklogsView =
    currentRoute.content === "home" || currentRoute.content === "backlogs";
  const isWorkItemsView = currentRoute.content === "work-items";
  const isTasksView = currentRoute.content === "tasks";
  const isBoardRoute = currentRoute.content === "board";
  const [isBoardMode, setIsBoardMode] = useState(false);
  const isBoardView = isBoardRoute || isBoardMode;
  const canCreateWorkItems =
    isBacklogsView || isWorkItemsView || isTasksView || isBoardRoute;
  const [visibleColumns, setVisibleColumns] = useState({
    order: true,
    id: true,
    type: true,
    title: true,
    state: true,
    progress: true,
    actions: true,
  });
  const [visibleBoardStates, setVisibleBoardStates] = useState<
    Record<WorkItemState, boolean>
  >({ New: true, Active: true, Closed: true });
  const [toast, setToast] = useState<ToastMessage | null>(null);
  const toastSequence = useRef(0);
  const showToast = useCallback((message: string, type: ToastMessage["type"]) => {
    toastSequence.current += 1;
    setToast({ id: toastSequence.current, message, type });
  }, []);
  const dismissToast = useCallback(() => setToast(null), []);

  useEffect(() => {
    if (mutationError) showToast(mutationError, "error");
  }, [mutationError, showToast]);

  const columnOptions: ColumnOption[] = isBoardView
    ? boardStates.map((state) => ({
        label: state,
        checked: visibleBoardStates[state],
        onToggle: () =>
          setVisibleBoardStates((current) => ({
            ...current,
            [state]: !current[state],
          })),
      }))
    : (isBacklogsView ? backlogColumns : workItemColumns).map((column) => ({
        label: column.label,
        checked: visibleColumns[column.key],
        onToggle: () =>
          setVisibleColumns((current) => ({
            ...current,
            [column.key]: !current[column.key],
          })),
      }));

  const displayedItems = isTasksView
    ? flatItems.filter((item) => item.type === "Task")
    : isBacklogsView
      ? visibleItems
      : flatItems;

  // En pantallas pequeñas el sidebar se abre y cierra con el botón de menú.
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const handleNavigate = (path: string) => {
    setIsCreating(false);
    setIsBoardMode(false);
    setIsMenuOpen(false);
    navigate(path);
  };

  return (
    <div className="app-shell flex min-h-screen w-full min-w-0 flex-col bg-linear-to-br from-sky-50 via-white to-blue-50 text-sm text-slate-700">
      <header className="sticky top-0 z-30 flex min-h-16 flex-wrap items-center justify-between gap-3 border-b border-sky-100 bg-white/85 px-4 py-3 shadow-sm backdrop-blur-sm sm:px-6">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => setIsMenuOpen((open) => !open)}
            aria-expanded={isMenuOpen}
            aria-controls="sidebar-principal"
            aria-label={isMenuOpen ? "Cerrar menú" : "Abrir menú"}
            className="flex h-10 w-10 cursor-pointer items-center justify-center rounded-lg border border-sky-100 bg-white text-slate-700 transition hover:bg-sky-50 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-500/40 lg:hidden"
          >
            <svg aria-hidden="true" viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
              {isMenuOpen ? (
                <path d="M6 6l12 12M18 6L6 18" />
              ) : (
                <path d="M4 6h16M4 12h16M4 18h16" />
              )}
            </svg>
          </button>
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
              <span aria-current="page" className="font-medium text-sky-700">
                {currentRoute.label}
              </span>
            </div>
          </div>
        </div>

        <div className="flex flex-1 flex-wrap items-center justify-end gap-3">
          <ThemeToggle isDarkMode={isDarkMode} onToggle={onToggleTheme} />
          {!isUsersView && (
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Buscar elementos..."
              aria-label="Buscar elementos de trabajo"
              className="w-full min-w-48 max-w-xs rounded-xl border border-slate-200 bg-slate-50 px-3.5 py-2 text-xs text-slate-800 outline-none transition placeholder:text-slate-400 focus:border-sky-400 focus:bg-white focus:ring-2 focus:ring-sky-500/20"
            />
          )}

          {onLogout && (
            <div className="flex items-center gap-3 text-xs text-slate-600">
              {userName && (
                <span className="max-w-40 shrink-0 truncate rounded-full bg-sky-50 px-3 py-2 font-medium text-sky-800">
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

      <div className="flex min-w-0 flex-1 flex-col lg:flex-row">
        <aside
          id="sidebar-principal"
          className={`${isMenuOpen ? "block" : "hidden"} w-full min-w-0 border-b border-sky-100 bg-white/65 p-3 lg:block lg:w-56 lg:shrink-0 lg:border-b-0 lg:border-r lg:p-4`}
        >
          <div className="mb-4 flex items-center gap-2 px-2 py-1.5 font-semibold text-slate-900">
            <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-linear-to-br from-sky-600 to-blue-600 text-xs text-white shadow-sm">
              DA
            </span>
            <span>Design Agile</span>
          </div>

          <nav
            aria-label="Navegación principal"
            className="flex flex-wrap gap-1 text-xs lg:flex-col"
          >
            {routes.map((route) => {
              const isActive = currentRoute.path === route.path;
              return (
                <button
                  key={route.path}
                  type="button"
                  onClick={() => handleNavigate(route.path)}
                  aria-current={isActive ? "page" : undefined}
                  className={`flex min-w-0 flex-1 basis-1/2 items-center justify-between rounded px-3 py-2 text-left transition lg:w-full lg:flex-none lg:basis-auto ${
                    isActive
                      ? "bg-sky-100 font-semibold text-sky-800 shadow-sm"
                      : "cursor-pointer text-slate-600 hover:bg-sky-50 hover:text-sky-800"
                  }`}
                >
                  <span className="break-words">{route.label}</span>
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
                {currentRoute.content === "sprints"
                  ? (activeSprint?.name ?? "Sprints")
                  : isBacklogsView
                    ? "Design Agile Team"
                    : isWorkItemsView
                      ? "Work Items"
                      : currentRoute.label}
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

          {canCreateWorkItems && (
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
                onClick={() =>
                  isBoardRoute
                    ? handleNavigate("/work-items")
                    : setIsBoardMode((previous) => !previous)
                }
                aria-pressed={isBoardView}
                className="cursor-pointer rounded-lg px-3 py-2 font-medium text-slate-600 transition hover:bg-sky-50 hover:text-sky-800"
              >
                {isBoardView ? "Vista de lista" : "Vista de tablero"}
              </button>
              <ColumnOptionsMenu options={columnOptions} />
            </div>
          )}

          {isCreating && canCreateWorkItems && (
            <NewWorkItemForm
              onSubmit={createWorkItem}
              onCancel={() => setIsCreating(false)}
              isSubmitting={isCreatingPending}
              parents={parentOptions}
              isLoadingParents={isParentOptionsLoading}
              initialType={isTasksView ? "Task" : "Epic"}
              error={mutationError ?? undefined}
              parentError={parentOptionsError}
            />
          )}

          {!isCreating &&
            (canCreateWorkItems || currentRoute.content === "sprints") &&
            mutationError && (
              <p
                role="alert"
                className="mb-4 rounded-xl border border-red-100 bg-red-50/80 px-4 py-3 text-xs text-red-700"
              >
                {mutationError}
              </p>
            )}

          {isUsersView ? (
            <UserManagementPage
              users={users}
              roles={roles}
              isLoading={isUsersLoading}
              error={usersError}
              isCreating={isUserCreating}
              onCreate={createUser}
              onCreated={(message) => showToast(message, "success")}
            />
          ) : currentRoute.content === "not-found" ? (
            <ModulePlaceholder title={currentRoute.label} notFound />
          ) : isLoading ? (
            <p className="py-6 text-xs text-slate-500">Cargando backlog...</p>
          ) : isError ? (
            <p className="rounded-xl border border-red-100 bg-red-50/80 px-4 py-3 text-xs text-red-700">
              {loadError}
            </p>
          ) : currentRoute.content === "sprints" ? (
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
          ) : isBoardView ? (
            <WorkItemsBoard
              items={displayedItems}
              visibleStates={boardStates.filter(
                (state) => visibleBoardStates[state],
              )}
              onRequestDelete={requestDeleteItem}
            />
          ) : isBacklogsView ? (
            <div className="overflow-x-auto rounded-2xl border border-slate-200/80 bg-white/90 p-4 shadow-lg shadow-sky-100/60">
              <table className="w-full min-w-[640px] border-collapse text-left text-xs">
                <thead>
                  <tr className="border-b border-slate-200 text-slate-500">
                    {visibleColumns.order && (
                      <th className="w-12 py-3 font-medium">Orden</th>
                    )}
                    {visibleColumns.title && (
                      <th className="py-3 font-medium">Título</th>
                    )}
                    {visibleColumns.state && (
                      <th className="w-28 py-3 font-medium">Estado</th>
                    )}
                    {visibleColumns.progress && (
                      <th className="w-44 py-3 font-medium">Progreso</th>
                    )}
                    {visibleColumns.actions && (
                      <th className="w-16 py-3 text-right font-medium">
                        Acciones
                      </th>
                    )}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {visibleItems.map((item) => (
                    <BacklogRow
                      key={item.id}
                      item={item}
                      isCollapsed={collapsedIds.has(item.id)}
                      columns={{
                        order: visibleColumns.order,
                        title: visibleColumns.title,
                        state: visibleColumns.state,
                        progress: visibleColumns.progress,
                        actions: visibleColumns.actions,
                      }}
                      onToggleCollapse={toggleCollapse}
                      onRequestDelete={requestDeleteItem}
                    />
                  ))}
                </tbody>
              </table>
            </div>
          ) : isWorkItemsView || isTasksView ? (
            <WorkItemsTable
              items={displayedItems}
              columns={visibleColumns}
              onRequestDelete={requestDeleteItem}
            />
          ) : (
            null
          )}
        </main>
      </div>

      <ConfirmDeleteModal
        item={itemToDelete}
        onConfirm={confirmDeleteItem}
        onCancel={cancelDeleteItem}
        isDeleting={isDeletingPending}
        error={mutationError}
      />
      <ToastNotification toast={toast} onDismiss={dismissToast} />
    </div>
  );
}
