defmodule PlanPickerWeb.PasswordAuthAuthTest do
  use PlanPickerWeb.ConnCase, async: true

  alias PlanPicker.Accounts
  alias PlanPickerWeb.PasswordAuthAuth
  import PlanPicker.AccountsFixtures

  @remember_me_cookie "_plan_picker_web_password_auth_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, PlanPickerWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{password_auth: password_auth_fixture(), conn: conn}
  end

  describe "log_in_password_auth/3" do
    test "stores the password_auth token in the session", %{conn: conn, password_auth: password_auth} do
      conn = PasswordAuthAuth.log_in_password_auth(conn, password_auth)
      assert token = get_session(conn, :password_auth_token)
      assert get_session(conn, :live_socket_id) == "password_auth_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Accounts.get_password_auth_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, password_auth: password_auth} do
      conn = conn |> put_session(:to_be_removed, "value") |> PasswordAuthAuth.log_in_password_auth(password_auth)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, password_auth: password_auth} do
      conn = conn |> put_session(:password_auth_return_to, "/hello") |> PasswordAuthAuth.log_in_password_auth(password_auth)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, password_auth: password_auth} do
      conn = conn |> fetch_cookies() |> PasswordAuthAuth.log_in_password_auth(password_auth, %{"remember_me" => "true"})
      assert get_session(conn, :password_auth_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :password_auth_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_password_auth/1" do
    test "erases session and cookies", %{conn: conn, password_auth: password_auth} do
      password_auth_token = Accounts.generate_password_auth_session_token(password_auth)

      conn =
        conn
        |> put_session(:password_auth_token, password_auth_token)
        |> put_req_cookie(@remember_me_cookie, password_auth_token)
        |> fetch_cookies()
        |> PasswordAuthAuth.log_out_password_auth()

      refute get_session(conn, :password_auth_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Accounts.get_password_auth_by_session_token(password_auth_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "password_auth_sessions:abcdef-token"
      PlanPickerWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> PasswordAuthAuth.log_out_password_auth()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "password_auth_sessions:abcdef-token"
      }
    end

    test "works even if password_auth is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> PasswordAuthAuth.log_out_password_auth()
      refute get_session(conn, :password_auth_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_password_auth/2" do
    test "authenticates password_auth from session", %{conn: conn, password_auth: password_auth} do
      password_auth_token = Accounts.generate_password_auth_session_token(password_auth)
      conn = conn |> put_session(:password_auth_token, password_auth_token) |> PasswordAuthAuth.fetch_current_password_auth([])
      assert conn.assigns.current_password_auth.id == password_auth.id
    end

    test "authenticates password_auth from cookies", %{conn: conn, password_auth: password_auth} do
      logged_in_conn =
        conn |> fetch_cookies() |> PasswordAuthAuth.log_in_password_auth(password_auth, %{"remember_me" => "true"})

      password_auth_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> PasswordAuthAuth.fetch_current_password_auth([])

      assert get_session(conn, :password_auth_token) == password_auth_token
      assert conn.assigns.current_password_auth.id == password_auth.id
    end

    test "does not authenticate if data is missing", %{conn: conn, password_auth: password_auth} do
      _ = Accounts.generate_password_auth_session_token(password_auth)
      conn = PasswordAuthAuth.fetch_current_password_auth(conn, [])
      refute get_session(conn, :password_auth_token)
      refute conn.assigns.current_password_auth
    end
  end

  describe "redirect_if_password_auth_is_authenticated/2" do
    test "redirects if password_auth is authenticated", %{conn: conn, password_auth: password_auth} do
      conn = conn |> assign(:current_password_auth, password_auth) |> PasswordAuthAuth.redirect_if_password_auth_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if password_auth is not authenticated", %{conn: conn} do
      conn = PasswordAuthAuth.redirect_if_password_auth_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_password_auth/2" do
    test "redirects if password_auth is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> PasswordAuthAuth.require_authenticated_password_auth([])
      assert conn.halted
      assert redirected_to(conn) == Routes.password_auth_session_path(conn, :new)
      assert get_flash(conn, :error) == "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | request_path: "/foo", query_string: ""}
        |> fetch_flash()
        |> PasswordAuthAuth.require_authenticated_password_auth([])

      assert halted_conn.halted
      assert get_session(halted_conn, :password_auth_return_to) == "/foo"

      halted_conn =
        %{conn | request_path: "/foo", query_string: "bar=baz"}
        |> fetch_flash()
        |> PasswordAuthAuth.require_authenticated_password_auth([])

      assert halted_conn.halted
      assert get_session(halted_conn, :password_auth_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | request_path: "/foo?bar", method: "POST"}
        |> fetch_flash()
        |> PasswordAuthAuth.require_authenticated_password_auth([])

      assert halted_conn.halted
      refute get_session(halted_conn, :password_auth_return_to)
    end

    test "does not redirect if password_auth is authenticated", %{conn: conn, password_auth: password_auth} do
      conn = conn |> assign(:current_password_auth, password_auth) |> PasswordAuthAuth.require_authenticated_password_auth([])
      refute conn.halted
      refute conn.status
    end
  end
end
