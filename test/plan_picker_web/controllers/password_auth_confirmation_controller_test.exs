defmodule PlanPickerWeb.PasswordAuthConfirmationControllerTest do
  use PlanPickerWeb.ConnCase, async: true

  alias PlanPicker.Accounts
  alias PlanPicker.Repo
  import PlanPicker.AccountsFixtures

  setup do
    %{password_auth: password_auth_fixture()}
  end

  describe "GET /password_auths/confirm" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.password_auth_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /password_auths/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, password_auth: password_auth} do
      conn =
        post(conn, Routes.password_auth_confirmation_path(conn, :create), %{
          "password_auth" => %{"email" => password_auth.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Accounts.PasswordAuthToken, password_auth_id: password_auth.id).context == "confirm"
    end

    test "does not send confirmation token if Password auth is confirmed", %{conn: conn, password_auth: password_auth} do
      Repo.update!(Accounts.PasswordAuth.confirm_changeset(password_auth))

      conn =
        post(conn, Routes.password_auth_confirmation_path(conn, :create), %{
          "password_auth" => %{"email" => password_auth.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Accounts.PasswordAuthToken, password_auth_id: password_auth.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.password_auth_confirmation_path(conn, :create), %{
          "password_auth" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.PasswordAuthToken) == []
    end
  end

  describe "GET /password_auths/confirm/:token" do
    test "confirms the given token once", %{conn: conn, password_auth: password_auth} do
      token =
        extract_password_auth_token(fn url ->
          Accounts.deliver_password_auth_confirmation_instructions(password_auth, url)
        end)

      conn = get(conn, Routes.password_auth_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Password auth confirmed successfully"
      assert Accounts.get_password_auth!(password_auth.id).confirmed_at
      refute get_session(conn, :password_auth_token)
      assert Repo.all(Accounts.PasswordAuthToken) == []

      # When not logged in
      conn = get(conn, Routes.password_auth_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Password auth confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_password_auth(password_auth)
        |> get(Routes.password_auth_confirmation_path(conn, :confirm, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, password_auth: password_auth} do
      conn = get(conn, Routes.password_auth_confirmation_path(conn, :confirm, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Password auth confirmation link is invalid or it has expired"
      refute Accounts.get_password_auth!(password_auth.id).confirmed_at
    end
  end
end
