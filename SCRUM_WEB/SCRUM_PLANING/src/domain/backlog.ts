export type WorkItemType = "Epic" | "Feature" | "Story" | "Task";
export type WorkItemState = "New" | "Active" | "Closed";
export type BacklogLevelFilter = "All" | "Epics" | "Features";
export type ActiveSection = "Backlogs" | "Work Items" | "Sprints";

export interface Sprint {
  id: number;
  name: string;
  startDate: string;
  endDate: string;
  workItemIds: string[];
}

export interface WorkItem {
  id: string;
  order: number;
  type: WorkItemType;
  title: string;
  state: string;
  level: number;
  parentId: string;
  description: string;
  acceptanceCriteria?: string | null;
  progress?: number;
  hasChildren?: boolean;
}

export interface WorkItemParentOption {
  id: string;
  title: string;
}

export type WorkItemParentOptions = Record<
  WorkItemType,
  WorkItemParentOption[]
>;

export function getVisibleBacklogItems(
  items: WorkItem[],
  options: {
    collapsedIds: Set<string>;
    search: string;
    selectedLevel: BacklogLevelFilter;
  },
): WorkItem[] {
  const { collapsedIds, search, selectedLevel } = options;
  const normalizedSearch = search.trim().toLowerCase();
  const visibleItems: WorkItem[] = [];
  let hiddenUntilLevel: number | null = null;

  for (const item of items) {
    if (hiddenUntilLevel !== null) {
      if (item.level > hiddenUntilLevel) {
        continue;
      }
      hiddenUntilLevel = null;
    }

    const matchesSearch =
      normalizedSearch === "" ||
      item.title.toLowerCase().includes(normalizedSearch);

    const matchesLevel =
      selectedLevel === "All" ||
      (selectedLevel === "Epics" && item.type === "Epic") ||
      (selectedLevel === "Features" &&
        (item.type === "Epic" || item.type === "Feature"));

    if (matchesSearch && matchesLevel) {
      visibleItems.push(item);
    }

    if (item.hasChildren && collapsedIds.has(item.id)) {
      hiddenUntilLevel = item.level;
    }
  }

  return visibleItems;
}
