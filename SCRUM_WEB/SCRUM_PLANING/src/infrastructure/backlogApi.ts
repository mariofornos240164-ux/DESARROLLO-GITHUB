import type {
  Sprint,
  WorkItem,
  WorkItemState,
  WorkItemType,
} from "../domain/backlog";
import { httpRequest } from "./httpClient";

export interface CreateWorkItemInput {
  title: string;
  type: WorkItemType;
  state: WorkItemState;
  parentId?: number | null;
  level?: number;
}

export const fetchWorkItems = async (): Promise<WorkItem[]> => {
  return httpRequest<WorkItem[]>("/work-items");
};

export const createWorkItem = async (
  input: CreateWorkItemInput,
): Promise<WorkItem> => {
  return httpRequest<WorkItem>("/work-items", {
    method: "POST",
    body: JSON.stringify(input),
  });
};

export const deleteWorkItem = async (id: number): Promise<number> => {
  await httpRequest<void>(`/work-items/${id}`, {
    method: "DELETE",
  });
  return id;
};

export const fetchSprints = async (): Promise<Sprint[]> => {
  return httpRequest<Sprint[]>("/sprints");
};

export const toggleWorkItemInSprint = async (
  sprintId: number,
  workItemId: number,
): Promise<Sprint[]> => {
  return httpRequest<Sprint[]>(
    `/sprints/${sprintId}/work-items/${workItemId}/toggle`,
    {
      method: "POST",
    },
  );
};
