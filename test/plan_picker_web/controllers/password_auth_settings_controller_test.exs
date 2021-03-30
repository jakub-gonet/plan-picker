defmodule PlanPickerWeb.PasswordAuthSettingsControllerTest do
  use PlanPickerWeb.ConnCase, async: true

  alias PlanPicker.Accounts
  import PlanPicker.AccountsFixtures

  setup :register_and_log_in_password_auth

  describe "GET /password_auth/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.password_auth_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if password_auth is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.password_auth_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.password_auth_session_path(conn, :new)
    end
  end

  describe "PUT /password_auth/settings (change password form)" do
    test "updates the password_auth password and resets tokens", %{conn: conn, password_auth: password_auth} do
      new_password_conn =
        put(conn, Routes.password_auth_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_password_auth_password(),
          "password_auth" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.password_auth_settings_path(conn, :edit)
      assert get_session(new_password_conn, :password_auth_token) != get_session(conn, :password_auth_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Accounts.get_password_auth_by_email_and_password(password_auth.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.password_auth_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "password_auth" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :password_auth_token) == get_session(conn, :password_auth_token)
    end
  end

  describe "PUT /password_auth/settings (change email form)" do
    @tag :capture_log
    test "updates the password_auth email", %{conn: conn, password_auth: password_auth} do
      conn =
        put(conn, Routes.password_auth_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_password_auth_password(),
          "password_auth" => %{"email" => unique_password_auth_email()}
        })

      assert redirected_to(conn) == Routes.password_auth_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert Accounts.get_password_auth_by_email(password_auth.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.password_auth_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "password_auth" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /password_auth/settings/confirm_email/:token" do
    setup %{password_auth: password_auth} do
      email = unique_password_auth_email()

      token =
        extract_password_auth_token(fn url ->
          Accounts.deliver_update_email_instructions(%{password_auth | email: email}, password_auth.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the password_auth email once", %{conn: conn, password_auth: password_auth, token: token, email: email} do
      conn = get(conn, Routes.password_auth_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.password_auth_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Accounts.get_password_auth_by_email(password_auth.email)
      assert Accounts.get_password_auth_by_email(email)

      conn = get(conn, Routes.password_auth_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.password_auth_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, password_auth: password_auth} do
      conn = get(conn, Routes.password_auth_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.password_auth_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Accounts.get_password_auth_by_email(password_auth.email)
    end

    test "redirects if password_auth is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.password_auth_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.password_auth_session_path(conn, :new)
    end
  end
end
