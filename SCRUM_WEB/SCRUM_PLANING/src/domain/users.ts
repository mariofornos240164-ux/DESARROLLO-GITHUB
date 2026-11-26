export interface UserRecord {
  userId: number;
  userFullName: string;
  userName: string;
  userEmail: string;
  userRolId: number;
  userEnable: boolean;
}

export interface RoleRecord {
  rolId: number;
  rolName: string;
  rolEnable: boolean;
}

export interface UserListResponse {
  status_code: number;
  message_user: string;
  data: UserRecord[];
}

export interface RoleListResponse {
  status_code: number;
  message_user: string;
  data: RoleRecord[];
}

export interface CreateUserInput {
  userFullName: string;
  userName: string;
  userEmail: string;
  userPassword: string;
  userRolId: number;
}

export interface UserOperationResponse {
  status_code: number;
  message_user: string;
}
