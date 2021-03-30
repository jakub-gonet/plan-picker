defmodule PlanPickerWeb.PasswordAuthSessionController do
  use PlanPickerWeb, :controller

  alias PlanPicker.Accounts
  alias PlanPickerWeb.PasswordAuthAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"password_auth" => password_auth_params}) do
    %{"email" => email, "password" => password} = password_auth_params

    if password_auth = Accounts.get_password_auth_by_email_and_password(email, password) do
      PasswordAuthAuth.log_in_password_auth(conn, password_auth, password_auth_params)
    else
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> PasswordAuthAuth.log_out_password_auth()
  end
end
