defmodule PlanPickerWeb.RoleHelpers do
  alias PlanPicker.Role
  alias PlanPickerWeb.UserAuth

  def user_has_role?(conn, role) do
    case UserAuth.current_user(conn) do
      nil -> false
      user -> Role.has_role?(user, role)
    end
  end

  def is_admin?(conn), do: user_has_role?(conn, :admin)

  def is_moderator?(conn), do: user_has_role?(conn, :moderator)
end
