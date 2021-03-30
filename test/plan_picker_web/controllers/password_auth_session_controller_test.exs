defmodule PlanPickerWeb.PasswordAuthSessionControllerTest do
  use PlanPickerWeb.ConnCase, async: true

  import PlanPicker.AccountsFixtures

  setup do
    %{password_auth: password_auth_fixture()}
  end

  describe "GET /password_auth/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.password_auth_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Log in</a>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{conn: conn, password_auth: password_auth} do
      conn = conn |> log_in_password_auth(password_auth) |> get(Routes.password_auth_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /password_auth/log_in" do
    test "logs the password_auth in", %{conn: conn, password_auth: password_auth} do
      conn =
        post(conn, Routes.password_auth_session_path(conn, :create), %{
          "password_auth" => %{"email" => password_auth.email, "password" => valid_password_auth_password()}
        })

      assert get_session(conn, :password_auth_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ password_auth.email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "logs the password_auth in with remember me", %{conn: conn, password_auth: password_auth} do
      conn =
        post(conn, Routes.password_auth_session_path(conn, :create), %{
          "password_auth" => %{
            "email" => password_auth.email,
            "password" => valid_password_auth_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_plan_picker_web_password_auth_remember_me"]
      assert redirected_to(conn) =~ "/"
    end

    test "logs the password_auth in with return to", %{conn: conn, password_auth: password_auth} do
      conn =
        conn
        |> init_test_session(password_auth_return_to: "/foo/bar")
        |> post(Routes.password_auth_session_path(conn, :create), %{
          "password_auth" => %{
            "email" => password_auth.email,
            "password" => valid_password_auth_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, password_auth: password_auth} do
      conn =
        post(conn, Routes.password_auth_session_path(conn, :create), %{
          "password_auth" => %{"email" => password_auth.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /password_auth/log_out" do
    test "logs the password_auth out", %{conn: conn, password_auth: password_auth} do
      conn = conn |> log_in_password_auth(password_auth) |> delete(Routes.password_auth_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :password_auth_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the password_auth is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.password_auth_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :password_auth_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end
