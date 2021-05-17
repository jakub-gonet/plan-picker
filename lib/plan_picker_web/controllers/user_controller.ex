defmodule PlanPickerWeb.UserController do
  use PlanPickerWeb, :controller

  def index(conn, _params) do
    users = PlanPicker.Accounts.User
    |> PlanPicker.Repo.all()

    render(conn, "index.html", users: users)
  end

end
