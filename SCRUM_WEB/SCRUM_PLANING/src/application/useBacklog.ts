import { useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  type ActiveSection,
  type BacklogLevelFilter,
  getVisibleBacklogItems,
  type Sprint,
  type WorkItem,
} from "../domain/backlog";
import {
  createWorkItem,
  type CreateWorkItemInput,
  deleteWorkItem,
  fetchSprints,
  fetchWorkItems,
  toggleWorkItemInSprint,
} from "../infrastructure/backlogApi";

export function useBacklog() {
  const queryClient = useQueryClient();

  const [activeSection, setActiveSection] = useState<ActiveSection>("Backlogs");
  const [selectedLevel, setSelectedLevel] = useState<BacklogLevelFilter>("All");
  const [search, setSearch] = useState("");
  const [collapsedIds, setCollapsedIds] = useState<Set<number>>(
    () => new Set(),
  );
  const [isCreating, setIsCreating] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<WorkItem | null>(null);
  const [selectedSprintId, setSelectedSprintId] = useState<number>(1);

  const {
    data: items = [],
    isLoading,
    isError,
  } = useQuery({
    queryKey: ["work-items"],
    queryFn: fetchWorkItems,
  });

  const { data: sprints = [] } = useQuery({
    queryKey: ["sprints"],
    queryFn: fetchSprints,
  });

  const createMutation = useMutation({
    mutationFn: (input: CreateWorkItemInput) => createWorkItem(input),
    onSuccess: (createdItem) => {
      queryClient.setQueryData<WorkItem[]>(["work-items"], (old = []) => {
        if (old.some((item) => item.id === createdItem.id)) {
          return old;
        }
        return [...old, createdItem];
      });
      setIsCreating(false);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => deleteWorkItem(id),
    onSuccess: (deletedId) => {
      queryClient.setQueryData<WorkItem[]>(["work-items"], (old = []) =>
        old.filter((item) => item.id !== deletedId),
      );
      setItemToDelete(null);
    },
  });

  const sprintToggleMutation = useMutation({
    mutationFn: ({
      sprintId,
      workItemId,
    }: {
      sprintId: number;
      workItemId: number;
    }) => toggleWorkItemInSprint(sprintId, workItemId),
    onSuccess: (updatedSprints) => {
      queryClient.setQueryData<Sprint[]>(["sprints"], updatedSprints);
    },
  });

  const requestDeleteItem = (item: WorkItem) => {
    setItemToDelete(item);
  };

  const cancelDeleteItem = () => {
    setItemToDelete(null);
  };

  const confirmDeleteItem = () => {
    if (!itemToDelete) return;
    deleteMutation.mutate(itemToDelete.id);
  };

  const toggleCollapse = (id: number) => {
    setCollapsedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const visibleItems = useMemo(
    () =>
      getVisibleBacklogItems(items, { collapsedIds, search, selectedLevel }),
    [items, collapsedIds, search, selectedLevel],
  );

  const flatItems = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return items;
    return items.filter((item) => item.title.toLowerCase().includes(query));
  }, [items, search]);

  const activeSprint = useMemo(
    () => sprints.find((s) => s.id === selectedSprintId) ?? sprints[0] ?? null,
    [sprints, selectedSprintId],
  );

  const sprintItems = useMemo(() => {
    if (!activeSprint) return [];
    const query = search.trim().toLowerCase();
    return items.filter((item) => {
      const inSprint = activeSprint.workItemIds.includes(item.id);
      if (!inSprint) return false;
      if (!query) return true;
      return item.title.toLowerCase().includes(query);
    });
  }, [items, activeSprint, search]);

  const availableForSprint = useMemo(() => {
    if (!activeSprint) return [];
    return items.filter((item) => !activeSprint.workItemIds.includes(item.id));
  }, [items, activeSprint]);

  return {
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
    createWorkItem: createMutation.mutate,
    isCreatingPending: createMutation.isPending,
    itemToDelete,
    requestDeleteItem,
    cancelDeleteItem,
    confirmDeleteItem,
    isDeletingPending: deleteMutation.isPending,
    sprints,
    activeSprint,
    selectedSprintId,
    setSelectedSprintId,
    sprintItems,
    availableForSprint,
    toggleItemInSprint: (workItemId: number) => {
      if (!activeSprint) return;
      sprintToggleMutation.mutate({ sprintId: activeSprint.id, workItemId });
    },
  };
}
