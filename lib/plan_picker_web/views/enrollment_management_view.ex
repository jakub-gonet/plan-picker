defmodule PlanPickerWeb.EnrollmentManagementView do
  use PlanPickerWeb, :view
  alias PlanPicker.Role
  alias PlanPickerWeb.UserAuth

  defp user_has_role?(conn, role) do
    conn |> UserAuth.current_user() |> Role.has_role?(role)
  end

  def is_admin?(conn), do: user_has_role?(conn, :admin)

  def selected?(selected, el) do
    Enum.member?(selected, el)
  end
end
