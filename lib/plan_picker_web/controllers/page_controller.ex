defmodule PlanPickerWeb.PageController do
  use PlanPickerWeb, :controller

  alias PlanPicker.Role

  def index(conn, _params) do
    case current_user = conn.assigns[:current_user] do
      nil ->
        render(conn, "anonymous_index.html")

      user ->
        render(conn, "index.html",
          is_moderator: Role.has_role?(user, :moderator),
          is_admin: Role.has_role?(user, :admin),
          current_user: current_user
        )
    end
  end
end
