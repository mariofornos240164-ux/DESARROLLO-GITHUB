import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import {
  createUser,
  fetchRoles,
  fetchUsers,
} from "../infrastructure/usersApi";

export function useUsers(enabled: boolean) {
  const queryClient = useQueryClient();
  const usersQuery = useQuery({
    queryKey: ["users"],
    queryFn: fetchUsers,
    enabled,
  });
  const rolesQuery = useQuery({
    queryKey: ["user-roles"],
    queryFn: fetchRoles,
    enabled,
  });
  const createMutation = useMutation({
    mutationFn: createUser,
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["users"] });
    },
  });

  const queryError = usersQuery.error ?? rolesQuery.error;

  return {
    users: usersQuery.data?.data ?? [],
    roles: (rolesQuery.data?.data ?? []).filter((role) => role.rolEnable),
    isLoading: usersQuery.isLoading || rolesQuery.isLoading,
    error:
      queryError instanceof Error
        ? queryError.message
        : queryError
          ? "No se pudo cargar la información de usuarios."
          : null,
    createUser: createMutation.mutateAsync,
    isCreating: createMutation.isPending,
  };
}
