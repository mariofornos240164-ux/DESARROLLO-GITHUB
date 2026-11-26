import { useEffect, useMemo, useState } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
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
  fetchWorkItemParents,
  fetchWorkItems,
  toggleWorkItemInSprint,
} from "../infrastructure/backlogApi";

function errorMessage(error: Error): string {
  return error.message || "No se pudo completar la operación.";
}

export function useBacklog() {
  const queryClient = useQueryClient();

  const [selectedLevel, setSelectedLevel] = useState<BacklogLevelFilter>("All");
  const [search, setSearch] = useState("");
  const [collapsedIds, setCollapsedIds] = useState<Set<string>>(
    () => new Set(),
  );
  const [isCreating, setIsCreating] = useState(false);
  const [itemToDelete, setItemToDelete] = useState<WorkItem | null>(null);
  const [selectedSprintId, setSelectedSprintId] = useState<number>(1);
  const [mutationError, setMutationError] = useState<string | null>(null);

  useEffect(() => {
    if (!mutationError) return;
    const timeoutId = window.setTimeout(() => setMutationError(null), 5000);
    return () => window.clearTimeout(timeoutId);
  }, [mutationError]);

  const {
    data: items = [],
    isLoading,
    isError,
    error: itemsError,
  } = useQuery({
    queryKey: ["work-items"],
    queryFn: fetchWorkItems,
  });

  const {
    data: parentOptions,
    isLoading: isParentOptionsLoading,
    error: parentOptionsError,
  } = useQuery({
    queryKey: ["work-item-parents"],
    queryFn: fetchWorkItemParents,
  });

  const { data: sprints = [] } = useQuery({
    queryKey: ["sprints"],
    queryFn: fetchSprints,
  });

  const createMutation = useMutation({
    mutationFn: (input: CreateWorkItemInput) => createWorkItem(input),
    onMutate: () => setMutationError(null),
    onSuccess: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ["work-items"] }),
        queryClient.invalidateQueries({ queryKey: ["work-item-parents"] }),
      ]);
      setIsCreating(false);
    },
    onError: (error) => setMutationError(errorMessage(error)),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => deleteWorkItem(id),
    onMutate: () => setMutationError(null),
    onSuccess: async () => {
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ["work-items"] }),
        queryClient.invalidateQueries({ queryKey: ["work-item-parents"] }),
        queryClient.invalidateQueries({ queryKey: ["sprints"] }),
      ]);
      setItemToDelete(null);
    },
    onError: (error) => setMutationError(errorMessage(error)),
  });

  const sprintToggleMutation = useMutation({
    mutationFn: ({
      sprintId,
      workItemId,
    }: {
      sprintId: number;
      workItemId: string;
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

  const toggleCollapse = (id: string) => {
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
    visibleItems,
    flatItems,
    isLoading,
    isError,
    loadError:
      itemsError instanceof Error ? itemsError.message : "Error al cargar el backlog.",
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
    parentOptions: parentOptions ?? {
      Epic: [],
      Feature: [],
      Story: [],
      Task: [],
    },
    isParentOptionsLoading,
    parentOptionsError:
      parentOptionsError instanceof Error ? parentOptionsError.message : null,
    mutationError,
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
    toggleItemInSprint: (workItemId: string) => {
      if (!activeSprint) return;
      sprintToggleMutation.mutate({ sprintId: activeSprint.id, workItemId });
    },
  };
}
