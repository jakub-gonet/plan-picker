defmodule PlanPickerWeb.PageController do
  use PlanPickerWeb, :controller

  def index(conn, _params) do
    case conn.assigns[:current_user] do
      nil -> render(conn, "anonymous_index.html")
      user ->
        moderator = PlanPicker.Role.has_role?(user, :moderator)
        admin = PlanPicker.Role.has_role?(user, :admin)
        render(conn, "index.html", is_moderator: moderator, is_admin: admin)
    end


  end
end
