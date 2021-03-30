defmodule PlanPickerWeb.PasswordAuthRegistrationController do
  use PlanPickerWeb, :controller

  alias PlanPicker.Accounts
  alias PlanPicker.Accounts.PasswordAuth
  alias PlanPickerWeb.PasswordAuthAuth

  def new(conn, _params) do
    changeset = Accounts.change_password_auth_registration(%PasswordAuth{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"password_auth" => password_auth_params}) do
    case Accounts.register_password_auth(password_auth_params) do
      {:ok, password_auth} ->
        {:ok, _} =
          Accounts.deliver_password_auth_confirmation_instructions(
            password_auth,
            &Routes.password_auth_confirmation_url(conn, :confirm, &1)
          )

        conn
        |> put_flash(:info, "Password auth created successfully.")
        |> PasswordAuthAuth.log_in_password_auth(password_auth)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
