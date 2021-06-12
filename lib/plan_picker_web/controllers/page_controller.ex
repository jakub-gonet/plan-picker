defmodule PlanPickerWeb.PageController do
  use PlanPickerWeb, :controller

  alias PlanPicker.Role

  def index(conn, _params) do
    case conn.assigns[:current_user] do
      nil ->
        render(conn, "anonymous_index.html")

      user ->
        moderator = Role.has_role?(user, :moderator)
        admin = Role.has_role?(user, :admin)
        render(conn, "index.html", is_moderator: moderator, is_admin: admin)
    end
  end
end
