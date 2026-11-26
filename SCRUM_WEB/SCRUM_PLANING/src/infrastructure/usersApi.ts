import type {
  CreateUserInput,
  RoleListResponse,
  UserListResponse,
  UserOperationResponse,
} from "../domain/users";
import { httpRequest } from "./httpClient";

const query = new URLSearchParams({
  page_number: "1",
  rows_per_page: "100",
});

export function fetchUsers(): Promise<UserListResponse> {
  return httpRequest<UserListResponse>(
    `/websocket/users/list?${query.toString()}`,
  );
}

export function fetchRoles(): Promise<RoleListResponse> {
  return httpRequest<RoleListResponse>(
    `/websocket/users/roles?${query.toString()}`,
  );
}

export function createUser(
  input: CreateUserInput,
): Promise<UserOperationResponse> {
  return httpRequest<UserOperationResponse>("/websocket/users/create", {
    method: "POST",
    body: JSON.stringify(input),
  });
}
