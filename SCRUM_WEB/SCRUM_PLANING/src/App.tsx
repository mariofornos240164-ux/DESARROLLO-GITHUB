import { useBacklog } from "./application/useBacklog";
import type { ActiveSection, BacklogLevelFilter } from "./domain/backlog";
import { BacklogRow } from "./presentation/BacklogRow";
import { ConfirmDeleteModal } from "./presentation/ConfirmDeleteModal";
import { NewWorkItemForm } from "./presentation/NewWorkItemForm";
import { SprintBoardView } from "./presentation/SprintBoardView";
import { WorkItemsTable } from "./presentation/WorkItemsTable";

export default function App() {
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
    <div className="flex min-h-screen w-full flex-col bg-white text-sm text-gray-800">
      <header className="flex h-12 items-center justify-between border-b border-gray-200 px-4">
        <div className="flex items-center gap-2 text-gray-600">
          <span className="font-semibold text-blue-600">Scrum Planning</span>
          <span>/</span>
          <span>Design Agile</span>
          <span>/</span>
          <span>Boards</span>
          <span>/</span>
          <span className="font-medium text-gray-900">{activeSection}</span>
        </div>

        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Search work items..."
          className="w-64 rounded border border-gray-300 bg-gray-50 px-3 py-1 text-xs focus:border-blue-500 focus:bg-white focus:outline-none"
        />
      </header>

      <div className="flex flex-1 overflow-hidden">
        <aside className="w-52 border-r border-gray-200 bg-[#f3f2f1] p-2">
          <div className="mb-3 flex items-center gap-2 px-2 py-1.5 font-semibold text-gray-900">
            <span className="flex h-6 w-6 items-center justify-center rounded bg-purple-700 text-xs text-white">
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
                      ? "bg-gray-300/70 font-semibold text-gray-900"
                      : isSelectable
                        ? "cursor-pointer text-gray-700 hover:bg-gray-200/60"
                        : "cursor-default text-gray-400"
                  }`}
                >
                  <span>{menu}</span>
                </button>
              );
            })}
          </nav>
        </aside>

        <main className="flex-1 overflow-auto p-6">
          <div className="mb-4 flex items-center justify-between">
            <h1 className="text-lg font-semibold text-gray-900">
              {activeSection === "Sprints"
                ? (activeSprint?.name ?? "Sprints")
                : isBacklogsView
                  ? "Design Agile Team"
                  : "Work Items"}
            </h1>

            {isBacklogsView && (
              <select
                value={selectedLevel}
                onChange={(e) =>
                  setSelectedLevel(e.target.value as BacklogLevelFilter)
                }
                className="rounded border border-gray-300 bg-white px-3 py-1 text-xs font-medium text-gray-700 hover:bg-gray-50"
              >
                <option value="All">Stories and Tasks</option>
                <option value="Features">Features</option>
                <option value="Epics">Epics</option>
              </select>
            )}
          </div>

          <div className="mb-3 flex items-center gap-4 border-b border-gray-200 pb-2 text-xs">
            <button
              type="button"
              onClick={() => setIsCreating((prev) => !prev)}
              className="flex cursor-pointer items-center gap-1 font-medium text-blue-600 hover:underline"
            >
              <span>+</span> New Work Item
            </button>
            <button type="button" className="text-gray-600 hover:text-gray-900">
              View as Board
            </button>
            <button type="button" className="text-gray-600 hover:text-gray-900">
              Column Options
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
            <p className="py-6 text-xs text-gray-500">Cargando backlog...</p>
          ) : isError ? (
            <p className="py-6 text-xs text-red-600">
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
            <table className="w-full border-collapse text-left text-xs">
              <thead>
                <tr className="border-b border-gray-200 text-gray-500">
                  <th className="w-12 py-2 font-medium">Order</th>
                  <th className="py-2 font-medium">Title</th>
                  <th className="w-28 py-2 font-medium">State</th>
                  <th className="w-44 py-2 font-medium">
                    Progress by all Work Items
                  </th>
                  <th className="w-16 py-2 text-right font-medium"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
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
