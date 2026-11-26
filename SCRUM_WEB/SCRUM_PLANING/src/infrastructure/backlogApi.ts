import type {
  Sprint,
  WorkItem,
  WorkItemParentOptions,
  WorkItemState,
  WorkItemType,
} from "../domain/backlog";
import { httpRequest } from "./httpClient";

export interface CreateWorkItemInput {
  title: string;
  description: string;
  acceptanceCriteria?: string;
  type: WorkItemType;
  state: WorkItemState;
  parentId: string;
}

interface OperationResponse {
  status_code: number;
  message_user: string;
}

export const fetchWorkItems = async (): Promise<WorkItem[]> => {
  return httpRequest<WorkItem[]>("/work-items");
};

export const fetchWorkItemParents = async (): Promise<WorkItemParentOptions> => {
  return httpRequest<WorkItemParentOptions>("/work-items/parents");
};

export const createWorkItem = async (
  input: CreateWorkItemInput,
): Promise<OperationResponse> => {
  return httpRequest<OperationResponse>("/work-items", {
    method: "POST",
    body: JSON.stringify(input),
  });
};

export const deleteWorkItem = async (id: string): Promise<string> => {
  await httpRequest<OperationResponse>(`/work-items/${encodeURIComponent(id)}`, {
    method: "DELETE",
  });
  return id;
};

export const fetchSprints = async (): Promise<Sprint[]> => {
  return httpRequest<Sprint[]>("/sprints");
};

export const toggleWorkItemInSprint = async (
  sprintId: number,
  workItemId: string,
): Promise<Sprint[]> => {
  return httpRequest<Sprint[]>(
    `/sprints/${sprintId}/work-items/${encodeURIComponent(workItemId)}/toggle`,
    {
      method: "POST",
    },
  );
};
