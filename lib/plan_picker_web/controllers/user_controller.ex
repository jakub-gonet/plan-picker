defmodule PlanPickerWeb.UserController do
  use PlanPickerWeb, :controller

  def index(conn, _params) do
    users = PlanPicker.Repo.all(PlanPicker.Accounts.User)

    render(conn, "index.html", users: users)
  end
end
