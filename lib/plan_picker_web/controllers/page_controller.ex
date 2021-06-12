defmodule PlanPickerWeb.PageController do
  use PlanPickerWeb, :controller
  import PlanPickerWeb.UserAuth, only: [current_user: 1]

  def index(conn, _params) do
    case current_user(conn) do
      nil ->
        render(conn, "anonymous_index.html")

      user ->
        render(conn, "index.html",
          is_moderator: Role.has_role?(user, :moderator),
          is_admin: Role.has_role?(user, :admin),
          current_user: user
        )
    end
  end
end
